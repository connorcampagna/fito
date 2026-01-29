/**
 * Fito Backend Server - Production Ready
 * Database: PostgreSQL with Prisma
 * Payments: Stripe
 * Auth: JWT with refresh tokens
 */

require('dotenv').config();
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const { GoogleGenerativeAI } = require('@google/generative-ai');
const { PrismaClient } = require('@prisma/client');
const { createClient } = require('@supabase/supabase-js');
const Stripe = require('stripe');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const Joi = require('joi');
const axios = require('axios');

const app = express();
const PORT = process.env.PORT || 3000;

// Initialize Prisma (reads DATABASE_URL from environment automatically)
const prisma = new PrismaClient();

// Initialize Stripe
const stripe = process.env.STRIPE_SECRET_KEY
  ? new Stripe(process.env.STRIPE_SECRET_KEY)
  : null;

// Lazy init Gemini
let genAI = null;
function getGenAI() {
  if (!genAI && process.env.GEMINI_API_KEY) {
    genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);
  }
  return genAI;
}

// Initialize Supabase (for image storage)
const supabaseUrl = process.env.SUPABASE_URL;
const supabaseServiceKey = process.env.SUPABASE_SERVICE_KEY;
const supabase = (supabaseUrl && supabaseServiceKey)
  ? createClient(supabaseUrl, supabaseServiceKey)
  : null;

// ============================================
// MIDDLEWARE
// ============================================

app.use(helmet());
app.use(cors({
  origin: process.env.NODE_ENV === 'production'
    ? ['https://yourdomain.com', 'capacitor://localhost', 'ionic://localhost']
    : '*',
  methods: ['GET', 'POST', 'PUT', 'DELETE'],
  allowedHeaders: ['Content-Type', 'Authorization']
}));

// Raw body for Stripe webhooks
app.use('/api/webhooks/stripe', express.raw({ type: 'application/json' }));
app.use(express.json({ limit: '10mb' }));

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 100,
  message: { error: 'Too many requests, please try again later' }
});
app.use(limiter);

// ============================================
// JWT AUTHENTICATION
// ============================================

const JWT_SECRET = process.env.JWT_SECRET;
const JWT_REFRESH_SECRET = process.env.JWT_REFRESH_SECRET;
const ACCESS_TOKEN_EXPIRY = '15m';
const REFRESH_TOKEN_EXPIRY = '7d';

// Validate secrets in production
if (process.env.NODE_ENV === 'production') {
  if (!JWT_SECRET || !JWT_REFRESH_SECRET) {
    console.error('FATAL: JWT_SECRET and JWT_REFRESH_SECRET must be set in production');
    process.exit(1);
  }
  if (JWT_SECRET.length < 32 || JWT_REFRESH_SECRET.length < 32) {
    console.error('FATAL: JWT secrets must be at least 32 characters');
    process.exit(1);
  }
}

function generateTokens(userId) {
  const accessToken = jwt.sign({ userId }, JWT_SECRET, { expiresIn: ACCESS_TOKEN_EXPIRY });
  const refreshToken = jwt.sign({ userId }, JWT_REFRESH_SECRET, { expiresIn: REFRESH_TOKEN_EXPIRY });
  return { accessToken, refreshToken };
}

function verifyAccessToken(token) {
  try {
    return jwt.verify(token, JWT_SECRET);
  } catch (error) {
    return null;
  }
}

// Auth middleware - extracts and verifies JWT
const authenticate = async (req, res, next) => {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'Unauthorized - No token provided' });
  }

  const token = authHeader.split(' ')[1];
  const decoded = verifyAccessToken(token);

  if (!decoded) {
    return res.status(401).json({ error: 'Unauthorized - Invalid or expired token' });
  }

  try {
    const user = await prisma.user.findUnique({
      where: { id: decoded.userId },
      include: { subscription: true }
    });

    if (!user) {
      return res.status(401).json({ error: 'User not found' });
    }

    req.user = user;
    req.userId = user.id;
    next();
  } catch (error) {
    console.error('Auth error:', error);
    return res.status(500).json({ error: 'Authentication failed' });
  }
};

// Subscription check middleware
const requireSubscription = (minTier) => {
  const tierLevels = { FREE: 0, PREMIUM: 1 };

  return async (req, res, next) => {
    const subscription = req.user.subscription;
    const userTier = subscription?.tier || 'FREE';

    if (tierLevels[userTier] < tierLevels[minTier]) {
      return res.status(403).json({
        error: 'Subscription required',
        requiredTier: minTier,
        currentTier: userTier,
        upgradeUrl: '/api/subscription/upgrade'
      });
    }
    next();
  };
};

// ============================================
// VALIDATION SCHEMAS
// ============================================

const schemas = {
  register: Joi.object({
    email: Joi.string().email().required(),
    password: Joi.string().min(8).required(),
    name: Joi.string().max(100).optional()
  }),
  login: Joi.object({
    email: Joi.string().email().required(),
    password: Joi.string().required()
  }),
  generateOutfit: Joi.object({
    prompt: Joi.string().max(500).required(),
    clothingItems: Joi.array().items(Joi.object({
      id: Joi.string().required(),
      category: Joi.string().required(),
      color: Joi.string().optional(),
      tags: Joi.array().items(Joi.string()).optional()
    })).min(1).required()
  }),
  updateProfile: Joi.object({
    name: Joi.string().max(100).optional(),
    gender: Joi.string().valid('male', 'female', 'non-binary', 'prefer-not-to-say').optional(),
    ageRange: Joi.string().valid('18-24', '25-34', '35-44', '45-54', '55+').optional()
  })
};

const validate = (schema) => (req, res, next) => {
  const { error } = schema.validate(req.body);
  if (error) {
    return res.status(400).json({ error: error.details[0].message });
  }
  next();
};

// ============================================
// SUBSCRIPTION TIERS CONFIG
// ============================================

const SUBSCRIPTION_TIERS = {
  FREE: {
    monthlyOutfitLimit: 5,
    savedOutfitLimit: 3,
    closetItemLimit: 20,
    features: ['5 generations per month', 'Basic AI styling', 'Save up to 3 outfits', 'Up to 20 closet items']
  },
  PREMIUM: {
    monthlyOutfitLimit: 100,
    savedOutfitLimit: -1, // Unlimited
    closetItemLimit: -1, // Unlimited
    price: 9.99,
    features: ['100 generations per month', 'Advanced AI with trends', 'Unlimited saved outfits', 'Unlimited closet items', 'Early access to features']
  }
};

// ============================================
// HEALTH & STATUS ENDPOINTS
// ============================================

app.get('/', (req, res) => {
  res.json({
    status: 'ok',
    service: 'Fito Backend',
    version: '2.0.0',
    database: 'PostgreSQL',
    payments: stripe ? 'Stripe' : 'disabled'
  });
});

app.get('/health', async (req, res) => {
  try {
    await prisma.$queryRaw`SELECT 1`;
    res.json({
      status: 'healthy',
      database: 'connected',
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    res.status(500).json({
      status: 'unhealthy',
      database: 'disconnected',
      error: error.message
    });
  }
});

// ============================================
// AUTH ENDPOINTS
// ============================================

// Register new user
app.post('/api/auth/register', validate(schemas.register), async (req, res) => {
  try {
    const { email, password, name } = req.body;

    // Check if user exists
    const existingUser = await prisma.user.findUnique({ where: { email } });
    if (existingUser) {
      return res.status(409).json({ error: 'Email already registered' });
    }

    // Hash password
    const passwordHash = await bcrypt.hash(password, 12);

    // Create user with free subscription
    const user = await prisma.user.create({
      data: {
        email,
        passwordHash,
        name,
        subscription: {
          create: {
            tier: 'FREE',
            status: 'ACTIVE',
            monthlyOutfitLimit: SUBSCRIPTION_TIERS.FREE.monthlyOutfitLimit
          }
        }
      },
      include: { subscription: true }
    });

    // Generate tokens
    const tokens = generateTokens(user.id);

    // Save refresh token
    await prisma.refreshToken.create({
      data: {
        token: tokens.refreshToken,
        userId: user.id,
        expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000)
      }
    });

    res.status(201).json({
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
      expiresIn: 900, // 15 minutes in seconds
      user: {
        id: user.id,
        email: user.email,
        name: user.name,
        tier: user.subscription.tier,
        isGuest: false
      }
    });
  } catch (error) {
    console.error('Registration error:', error);
    res.status(500).json({ error: 'Registration failed' });
  }
});

// Login
app.post('/api/auth/login', validate(schemas.login), async (req, res) => {
  try {
    const { email, password } = req.body;

    const user = await prisma.user.findUnique({
      where: { email },
      include: { subscription: true }
    });

    if (!user || !user.passwordHash) {
      return res.status(401).json({ error: 'Invalid email or password' });
    }

    const validPassword = await bcrypt.compare(password, user.passwordHash);
    if (!validPassword) {
      return res.status(401).json({ error: 'Invalid email or password' });
    }

    // Update last login
    await prisma.user.update({
      where: { id: user.id },
      data: { lastLoginAt: new Date() }
    });

    // Generate tokens
    const tokens = generateTokens(user.id);

    // Save refresh token
    await prisma.refreshToken.create({
      data: {
        token: tokens.refreshToken,
        userId: user.id,
        expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000)
      }
    });

    res.json({
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
      expiresIn: 900, // 15 minutes in seconds
      user: {
        id: user.id,
        email: user.email,
        name: user.name,
        tier: user.subscription?.tier || 'FREE',
        isGuest: false
      }
    });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ error: 'Login failed' });
  }
});

// Refresh token
app.post('/api/auth/refresh', async (req, res) => {
  try {
    const { refreshToken } = req.body;
    if (!refreshToken) {
      return res.status(400).json({ error: 'Refresh token required' });
    }

    // Verify refresh token
    let decoded;
    try {
      decoded = jwt.verify(refreshToken, JWT_REFRESH_SECRET);
    } catch (error) {
      return res.status(401).json({ error: 'Invalid refresh token' });
    }

    // Check if token exists in database
    const storedToken = await prisma.refreshToken.findUnique({
      where: { token: refreshToken }
    });

    if (!storedToken || storedToken.expiresAt < new Date()) {
      return res.status(401).json({ error: 'Refresh token expired' });
    }

    // Delete old refresh token
    await prisma.refreshToken.delete({ where: { id: storedToken.id } });

    // Generate new tokens
    const tokens = generateTokens(decoded.userId);

    // Save new refresh token
    await prisma.refreshToken.create({
      data: {
        token: tokens.refreshToken,
        userId: decoded.userId,
        expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000)
      }
    });

    // Get user info for response
    const user = await prisma.user.findUnique({
      where: { id: decoded.userId },
      include: { subscription: true }
    });

    res.json({
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
      expiresIn: 900,
      user: {
        id: user.id,
        email: user.email,
        name: user.name,
        tier: user.subscription?.tier || 'FREE',
        isGuest: user.email?.includes('@fito.app') || false
      }
    });
  } catch (error) {
    console.error('Token refresh error:', error);
    res.status(500).json({ error: 'Token refresh failed' });
  }
});


// ============================================
// SUBSCRIPTION & PAYMENT ENDPOINTS
// ============================================

// Get subscription status
app.get('/api/subscription', authenticate, async (req, res) => {
  try {
    const subscription = req.user.subscription;

    if (!subscription) {
      return res.json({
        tier: 'FREE',
        status: 'ACTIVE',
        monthlyLimit: SUBSCRIPTION_TIERS.FREE.monthlyOutfitLimit,
        monthlyUsed: 0,
        features: SUBSCRIPTION_TIERS.FREE.features
      });
    }

    // Check if usage needs reset (new month)
    const now = new Date();
    if (subscription.usageResetDate < new Date(now.getFullYear(), now.getMonth(), 1)) {
      await prisma.subscription.update({
        where: { id: subscription.id },
        data: {
          monthlyOutfitsUsed: 0,
          usageResetDate: now
        }
      });
      subscription.monthlyOutfitsUsed = 0;
    }

    // Get tier config for limits
    const tierConfig = SUBSCRIPTION_TIERS[subscription.tier] || SUBSCRIPTION_TIERS.FREE;

    res.json({
      tier: subscription.tier,
      status: subscription.status,
      monthlyLimit: subscription.tier === 'PREMIUM' ? 'Unlimited' : tierConfig.monthlyOutfitLimit,
      monthlyUsed: subscription.monthlyOutfitsUsed,
      currentPeriodEnd: subscription.currentPeriodEnd,
      cancelAtPeriodEnd: subscription.cancelAtPeriodEnd,
      features: tierConfig.features || []
    });
  } catch (error) {
    console.error('Get subscription error:', error);
    res.status(500).json({ error: 'Failed to get subscription' });
  }
});

// Get available subscription plans
app.get('/api/subscription/plans', (req, res) => {
  res.json({
    plans: [
      {
        tier: 'FREE',
        name: 'Free',
        price: 0,
        interval: 'month',
        features: SUBSCRIPTION_TIERS.FREE.features,
        cta: 'Current Plan'
      },
      {
        tier: 'PREMIUM',
        name: 'Premium',
        price: 9.99,
        priceId: process.env.STRIPE_PREMIUM_PRICE_ID,
        interval: 'month',
        features: SUBSCRIPTION_TIERS.PREMIUM.features,
        cta: 'Go Premium'
      }
    ]
  });
});

// Create Stripe checkout session
app.post('/api/subscription/checkout', authenticate, async (req, res) => {
  try {
    if (!stripe) {
      return res.status(503).json({ error: 'Payments not configured' });
    }

    const { tier } = req.body;

    if (!['PREMIUM'].includes(tier)) {
      return res.status(400).json({ error: 'Invalid subscription tier' });
    }

    const priceId = tier === 'PREMIUM'
      ? process.env.STRIPE_PREMIUM_PRICE_ID
      : process.env.STRIPE_PREMIUM_PRICE_ID;

    if (!priceId) {
      return res.status(503).json({ error: 'Price not configured' });
    }

    // Get or create Stripe customer
    let customerId = req.user.subscription?.stripeCustomerId;

    if (!customerId) {
      const customer = await stripe.customers.create({
        email: req.user.email,
        metadata: { userId: req.user.id }
      });
      customerId = customer.id;

      await prisma.subscription.update({
        where: { userId: req.user.id },
        data: { stripeCustomerId: customerId }
      });
    }

    // Create checkout session
    const session = await stripe.checkout.sessions.create({
      customer: customerId,
      payment_method_types: ['card'],
      line_items: [{
        price: priceId,
        quantity: 1
      }],
      mode: 'subscription',
      success_url: `${process.env.APP_URL || 'fito://'}subscription/success?session_id={CHECKOUT_SESSION_ID}`,
      cancel_url: `${process.env.APP_URL || 'fito://'}subscription/cancel`,
      metadata: {
        userId: req.user.id,
        tier: tier
      }
    });

    res.json({
      sessionId: session.id,
      url: session.url
    });
  } catch (error) {
    console.error('Checkout error:', error);
    res.status(500).json({ error: 'Failed to create checkout session' });
  }
});

// Create Stripe customer portal session (for managing subscription)
app.post('/api/subscription/portal', authenticate, async (req, res) => {
  try {
    if (!stripe) {
      return res.status(503).json({ error: 'Payments not configured' });
    }

    const customerId = req.user.subscription?.stripeCustomerId;
    if (!customerId) {
      return res.status(400).json({ error: 'No subscription found' });
    }

    const session = await stripe.billingPortal.sessions.create({
      customer: customerId,
      return_url: `${process.env.APP_URL || 'fito://'}profile`
    });

    res.json({ url: session.url });
  } catch (error) {
    console.error('Portal error:', error);
    res.status(500).json({ error: 'Failed to create portal session' });
  }
});

// Stripe webhook handler
app.post('/api/webhooks/stripe', async (req, res) => {
  if (!stripe) {
    return res.status(503).json({ error: 'Payments not configured' });
  }

  const sig = req.headers['stripe-signature'];
  const webhookSecret = process.env.STRIPE_WEBHOOK_SECRET;

  let event;
  try {
    event = stripe.webhooks.constructEvent(req.body, sig, webhookSecret);
  } catch (err) {
    console.error('Webhook signature verification failed:', err.message);
    return res.status(400).json({ error: 'Webhook signature verification failed' });
  }

  console.log('Stripe webhook:', event.type);

  try {
    switch (event.type) {
      case 'checkout.session.completed': {
        const session = event.data.object;
        const userId = session.metadata?.userId;
        const tier = session.metadata?.tier;

        if (userId && tier) {
          await prisma.subscription.update({
            where: { userId },
            data: {
              tier: tier,
              status: 'ACTIVE',
              stripeSubscriptionId: session.subscription,
              monthlyOutfitLimit: SUBSCRIPTION_TIERS[tier].monthlyOutfitLimit,
              currentPeriodStart: new Date(),
              currentPeriodEnd: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000)
            }
          });

          await prisma.usageLog.create({
            data: {
              userId,
              action: 'SUBSCRIPTION_STARTED',
              metadata: { tier, sessionId: session.id }
            }
          });
        }
        break;
      }

      case 'customer.subscription.updated': {
        const subscription = event.data.object;
        const customer = await stripe.customers.retrieve(subscription.customer);
        const userId = customer.metadata?.userId;

        if (userId) {
          await prisma.subscription.update({
            where: { userId },
            data: {
              status: subscription.status === 'active' ? 'ACTIVE' : 'PAST_DUE',
              cancelAtPeriodEnd: subscription.cancel_at_period_end,
              currentPeriodEnd: new Date(subscription.current_period_end * 1000)
            }
          });
        }
        break;
      }

      case 'customer.subscription.deleted': {
        const subscription = event.data.object;
        const customer = await stripe.customers.retrieve(subscription.customer);
        const userId = customer.metadata?.userId;

        if (userId) {
          await prisma.subscription.update({
            where: { userId },
            data: {
              tier: 'FREE',
              status: 'CANCELED',
              monthlyOutfitLimit: SUBSCRIPTION_TIERS.FREE.monthlyOutfitLimit
            }
          });

          await prisma.usageLog.create({
            data: {
              userId,
              action: 'SUBSCRIPTION_CANCELED',
              metadata: { subscriptionId: subscription.id }
            }
          });
        }
        break;
      }

      case 'invoice.payment_failed': {
        const invoice = event.data.object;
        const customer = await stripe.customers.retrieve(invoice.customer);
        const userId = customer.metadata?.userId;

        if (userId) {
          await prisma.subscription.update({
            where: { userId },
            data: { status: 'PAST_DUE' }
          });
        }
        break;
      }
    }

    res.json({ received: true });
  } catch (error) {
    console.error('Webhook processing error:', error);
    res.status(500).json({ error: 'Webhook processing failed' });
  }
});

// Apple IAP verification
app.post('/api/subscription/verify-apple', authenticate, async (req, res) => {
  try {
    const { receiptData, productId } = req.body;

    if (!receiptData || !productId) {
      return res.status(400).json({ error: 'Receipt data and product ID required' });
    }

    // Verify receipt with Apple's servers
    const verifyUrl = process.env.NODE_ENV === 'production'
      ? 'https://buy.itunes.apple.com/verifyReceipt'
      : 'https://sandbox.itunes.apple.com/verifyReceipt';

    const verifyResponse = await axios.post(verifyUrl, {
      'receipt-data': receiptData,
      'password': process.env.APPLE_SHARED_SECRET, // App-specific shared secret from App Store Connect
      'exclude-old-transactions': true
    });

    const appleResponse = verifyResponse.data;

    // Check response status
    // 0 = valid, 21007 = sandbox receipt sent to production (retry with sandbox)
    if (appleResponse.status === 21007) {
      // Retry with sandbox URL
      const sandboxResponse = await axios.post('https://sandbox.itunes.apple.com/verifyReceipt', {
        'receipt-data': receiptData,
        'password': process.env.APPLE_SHARED_SECRET,
        'exclude-old-transactions': true
      });
      appleResponse.status = sandboxResponse.data.status;
      appleResponse.latest_receipt_info = sandboxResponse.data.latest_receipt_info;
    }

    if (appleResponse.status !== 0) {
      console.error('Apple receipt verification failed:', appleResponse.status);
      return res.status(400).json({
        error: 'Invalid receipt',
        appleStatus: appleResponse.status
      });
    }

    // Find the purchased product in the receipt
    const latestReceipts = appleResponse.latest_receipt_info || [];
    const purchasedProduct = latestReceipts.find(r => r.product_id === productId);

    if (!purchasedProduct) {
      return res.status(400).json({ error: 'Product not found in receipt' });
    }

    // Check if subscription is still active
    const expiresDate = new Date(parseInt(purchasedProduct.expires_date_ms));
    if (expiresDate < new Date()) {
      return res.status(400).json({ error: 'Subscription expired' });
    }

    // Determine tier from product ID
    const tier = productId.includes('premium') ? 'PREMIUM' : 'FREE';

    // Update subscription in database
    await prisma.subscription.update({
      where: { userId: req.user.id },
      data: {
        tier: tier,
        status: 'ACTIVE',
        appleProductId: productId,
        appleOriginalTransactionId: purchasedProduct.original_transaction_id,
        monthlyOutfitLimit: SUBSCRIPTION_TIERS[tier]?.monthlyOutfitLimit || -1,
        currentPeriodStart: new Date(parseInt(purchasedProduct.purchase_date_ms)),
        currentPeriodEnd: expiresDate
      }
    });

    // Log the purchase
    await prisma.usageLog.create({
      data: {
        userId: req.user.id,
        action: 'APPLE_IAP_VERIFIED',
        metadata: {
          productId,
          transactionId: purchasedProduct.transaction_id,
          expiresDate: expiresDate.toISOString()
        }
      }
    });

    res.json({
      success: true,
      subscription: {
        tier,
        status: 'ACTIVE',
        expiresDate: expiresDate.toISOString()
      }
    });
  } catch (error) {
    console.error('Apple IAP verification error:', error);
    res.status(500).json({ error: 'Verification failed' });
  }
});

// ============================================
// USER PROFILE ENDPOINTS
// ============================================

app.get('/api/profile', authenticate, async (req, res) => {
  try {
    // Determine if profile is complete (has gender and ageRange set)
    const profileCompleted = !!(req.user.gender && req.user.ageRange);

    res.json({
      id: req.user.id,
      email: req.user.email,
      name: req.user.name,
      profileImage: req.user.profileImage,
      gender: req.user.gender,
      ageRange: req.user.ageRange,
      profileCompleted: profileCompleted,
      createdAt: req.user.createdAt,
      subscription: {
        tier: req.user.subscription?.tier || 'FREE',
        status: req.user.subscription?.status || 'ACTIVE',
        monthlyLimit: req.user.subscription?.monthlyOutfitLimit || 10,
        monthlyUsed: req.user.subscription?.monthlyOutfitsUsed || 0
      }
    });
  } catch (error) {
    console.error('Get profile error:', error);
    res.status(500).json({ error: 'Failed to get profile' });
  }
});

app.put('/api/profile', authenticate, validate(schemas.updateProfile), async (req, res) => {
  try {
    const { name, gender, ageRange } = req.body;

    const user = await prisma.user.update({
      where: { id: req.user.id },
      data: { name, gender, ageRange }
    });

    res.json({
      id: user.id,
      email: user.email,
      name: user.name,
      gender: user.gender,
      ageRange: user.ageRange
    });
  } catch (error) {
    console.error('Update profile error:', error);
    res.status(500).json({ error: 'Failed to update profile' });
  }
});

// Upload profile image to Supabase Storage
app.post('/api/profile/image', authenticate, async (req, res) => {
  try {
    const { imageBase64 } = req.body;

    if (!imageBase64) {
      return res.status(400).json({ error: 'Image data required' });
    }

    if (!supabase) {
      return res.status(503).json({ error: 'Image storage not configured' });
    }

    // Decode base64 and upload to Supabase Storage
    const imageBuffer = Buffer.from(imageBase64, 'base64');
    const fileName = `profile-${req.user.id}-${Date.now()}.jpg`;

    const { data, error: uploadError } = await supabase.storage
      .from('profile-images')
      .upload(fileName, imageBuffer, {
        contentType: 'image/jpeg',
        upsert: true
      });

    if (uploadError) {
      console.error('Supabase upload error:', uploadError);
      return res.status(500).json({ error: 'Failed to upload image' });
    }

    // Get public URL
    const { data: urlData } = supabase.storage
      .from('profile-images')
      .getPublicUrl(fileName);

    const imageUrl = urlData.publicUrl;

    // Update user profile with image URL
    await prisma.user.update({
      where: { id: req.user.id },
      data: { profileImage: imageUrl }
    });

    res.json({ imageUrl });
  } catch (error) {
    console.error('Profile image upload error:', error);
    res.status(500).json({ error: 'Failed to upload image' });
  }
});

// Complete profile setup (initial onboarding)
app.post('/api/profile/complete', authenticate, async (req, res) => {
  try {
    const { name, gender, ageRange, profileImage } = req.body;

    if (!gender || !ageRange) {
      return res.status(400).json({ error: 'Gender and age range are required' });
    }

    const updateData = {
      gender,
      ageRange
    };

    if (name) updateData.name = name;
    if (profileImage) updateData.profileImage = profileImage;

    const user = await prisma.user.update({
      where: { id: req.user.id },
      data: updateData,
      include: { subscription: true }
    });

    res.json({
      success: true,
      user: {
        id: user.id,
        email: user.email,
        name: user.name,
        gender: user.gender,
        ageRange: user.ageRange,
        profileImage: user.profileImage,
        profileCompleted: true,
        subscription: {
          tier: user.subscription?.tier || 'FREE',
          status: user.subscription?.status || 'ACTIVE'
        }
      }
    });
  } catch (error) {
    console.error('Complete profile error:', error);
    res.status(500).json({ error: 'Failed to complete profile' });
  }
});

// ============================================
// OUTFIT GENERATION (with usage tracking)
// ============================================

app.post('/api/generate-outfit', authenticate, validate(schemas.generateOutfit), async (req, res) => {
  try {
    const { prompt, clothingItems } = req.body;
    const subscription = req.user.subscription;

    // Check usage limits (skip for PREMIUM - unlimited)
    if (subscription?.tier !== 'PREMIUM') {
      const limit = subscription?.monthlyOutfitLimit || 10;
      const used = subscription?.monthlyOutfitsUsed || 0;

      if (used >= limit) {
        return res.status(429).json({
          error: 'Monthly limit reached',
          code: 'USAGE_LIMIT_REACHED',
          limit,
          used,
          upgradeUrl: '/api/subscription/plans'
        });
      }
    }

    // Generate outfit with AI
    const ai = getGenAI();
    if (!ai) {
      return res.status(503).json({ error: 'AI service unavailable' });
    }

    // Group items by category for better AI understanding
    const tops = clothingItems.filter(i => i.category === 'top');
    const bottoms = clothingItems.filter(i => i.category === 'bottom');
    const shoes = clothingItems.filter(i => i.category === 'shoes');
    const outerwear = clothingItems.filter(i => i.category === 'outerwear');

    const formatItems = (items, category) => items.map((item, idx) =>
      `  ${idx + 1}. ID: "${item.id}" - Tags: [${item.tags?.join(', ') || 'none'}]`
    ).join('\n');

    const aiPrompt = `You are a professional fashion stylist, named FITO. Select the best outfit for: "${prompt}"

AVAILABLE ITEMS (select ONE from each category that has items):

TOPS:
${tops.length > 0 ? formatItems(tops, 'top') : '  (none available)'}

BOTTOMS:
${bottoms.length > 0 ? formatItems(bottoms, 'bottom') : '  (none available)'}

SHOES:
${shoes.length > 0 ? formatItems(shoes, 'shoes') : '  (none available)'}

OUTERWEAR:
${outerwear.length > 0 ? formatItems(outerwear, 'outerwear') : '  (none available)'}

Select items that work well together for the occasion. If a category has no suitable items or is empty, set that ID to null.

Respond ONLY with valid JSON (no markdown):
{
  "top_id": "selected-top-id-or-null",
  "bottom_id": "selected-bottom-id-or-null",
  "shoes_id": "selected-shoes-id-or-null",
  "outerwear_id": "selected-outerwear-id-or-null-if-not-needed",
  "reasoning": "Brief explanation of why these items work together for the occasion",
  "style_tip": "One helpful styling tip for wearing this outfit"
}`;

    const model = ai.getGenerativeModel({ model: 'gemini-2.5-flash' });
    const result = await model.generateContent(aiPrompt);
    const content = result.response.text();
    const jsonMatch = content.match(/\{[\s\S]*\}/);

    if (!jsonMatch) {
      return res.status(500).json({ error: 'Failed to generate outfit' });
    }

    const outfit = JSON.parse(jsonMatch[0]);

    // Validate that selected IDs exist in the provided items
    const allItemIds = clothingItems.map(i => i.id);
    const validatedOutfit = {
      top_id: allItemIds.includes(outfit.top_id) ? outfit.top_id : null,
      bottom_id: allItemIds.includes(outfit.bottom_id) ? outfit.bottom_id : null,
      shoes_id: allItemIds.includes(outfit.shoes_id) ? outfit.shoes_id : null,
      outerwear_id: allItemIds.includes(outfit.outerwear_id) ? outfit.outerwear_id : null,
      reasoning: outfit.reasoning || "A stylish outfit for your occasion!",
      style_tip: outfit.style_tip || "Accessorize to make it your own!",
      notSuitable: !outfit.top_id && !outfit.bottom_id && !outfit.shoes_id
    };

    // Increment usage
    if (subscription) {
      await prisma.subscription.update({
        where: { id: subscription.id },
        data: { monthlyOutfitsUsed: { increment: 1 } }
      });
    }

    // Log usage
    await prisma.usageLog.create({
      data: {
        userId: req.user.id,
        action: 'OUTFIT_GENERATED',
        metadata: { prompt, itemCount: clothingItems.length }
      }
    });

    res.json(validatedOutfit);
  } catch (error) {
    console.error('Generate outfit error:', error);
    res.status(500).json({ error: 'Failed to generate outfit' });
  }
});


// ============================================
// VIRTUAL TRY-ON (Nano Banana API)
// ============================================

const NANO_BANANA_API_KEY = process.env.NANO_BANANA_API_KEY;
const NANO_BANANA_BASE_URL = 'https://api.fashn.ai/v1';

// Virtual Try-On endpoint
app.post('/api/tryon/generate', authenticate, async (req, res) => {
  try {
    const { personImage, clothingImage, mode = 'quality' } = req.body;

    if (!personImage || !clothingImage) {
      return res.status(400).json({ error: 'Both person and clothing images are required' });
    }

    if (!NANO_BANANA_API_KEY) {
      return res.status(503).json({ error: 'Virtual try-on service not configured' });
    }

    // Check subscription - require PRO or higher for try-on
    const subscription = req.user.subscription;
    if (!subscription || subscription.tier === 'FREE') {
      return res.status(403).json({
        error: 'Virtual try-on requires Fito Pro subscription',
        requiredTier: 'PRO',
        currentTier: subscription?.tier || 'FREE'
      });
    }

    // Log usage
    await prisma.usageLog.create({
      data: {
        userId: req.user.id,
        action: 'TRYON_GENERATED'
      }
    });

    // Call Nano Banana / FASHN API
    const response = await axios.post(
      `${NANO_BANANA_BASE_URL}/run`,
      {
        model_image: personImage,  // Base64 encoded person image
        garment_image: clothingImage,  // Base64 encoded clothing image
        category: 'auto',  // auto-detect clothing category
        mode: mode === 'fast' ? 'speed' : 'quality',
        nsfw_filter: true,
        cover_feet: false,
        adjust_hands: true,
        restore_background: true,
        restore_clothes: true,
        garment_photo_type: 'auto',
        long_top: false,
        seed: Math.floor(Math.random() * 1000000)
      },
      {
        headers: {
          'Authorization': `Bearer ${NANO_BANANA_API_KEY}`,
          'Content-Type': 'application/json'
        },
        timeout: 120000  // 2 minute timeout
      }
    );

    // Get prediction ID and poll for result
    const predictionId = response.data.id;

    if (!predictionId) {
      throw new Error('No prediction ID returned');
    }

    // Poll for completion (FASHN API is async)
    let result = null;
    let attempts = 0;
    const maxAttempts = 60;  // Max 2 minutes of polling

    while (!result && attempts < maxAttempts) {
      await new Promise(resolve => setTimeout(resolve, 2000));  // Wait 2 seconds

      const statusResponse = await axios.get(
        `${NANO_BANANA_BASE_URL}/status/${predictionId}`,
        {
          headers: {
            'Authorization': `Bearer ${NANO_BANANA_API_KEY}`
          }
        }
      );

      const status = statusResponse.data.status;

      if (status === 'completed') {
        result = statusResponse.data.output;
        break;
      } else if (status === 'failed') {
        throw new Error(statusResponse.data.error || 'Try-on generation failed');
      }

      attempts++;
    }

    if (!result) {
      throw new Error('Try-on generation timed out');
    }

    res.json({
      success: true,
      resultImage: result,  // Base64 or URL of the result image
      predictionId: predictionId
    });

  } catch (error) {
    console.error('Virtual try-on error:', error.response?.data || error.message);

    if (error.response?.status === 401) {
      return res.status(503).json({ error: 'Try-on service authentication failed' });
    }
    if (error.response?.status === 429) {
      return res.status(429).json({ error: 'Too many try-on requests. Please try again later.' });
    }

    res.status(500).json({ error: 'Virtual try-on failed. Please try again.' });
  }
});

// Check try-on status (for polling from client if needed)
app.get('/api/tryon/status/:predictionId', authenticate, async (req, res) => {
  try {
    const { predictionId } = req.params;

    if (!NANO_BANANA_API_KEY) {
      return res.status(503).json({ error: 'Virtual try-on service not configured' });
    }

    const response = await axios.get(
      `${NANO_BANANA_BASE_URL}/status/${predictionId}`,
      {
        headers: {
          'Authorization': `Bearer ${NANO_BANANA_API_KEY}`
        }
      }
    );

    res.json({
      status: response.data.status,
      output: response.data.output || null,
      error: response.data.error || null
    });

  } catch (error) {
    console.error('Try-on status error:', error.response?.data || error.message);
    res.status(500).json({ error: 'Failed to check try-on status' });
  }
});

// ============================================
// ANALYTICS ENDPOINTS
// ============================================

app.get('/api/analytics/usage', authenticate, async (req, res) => {
  try {
    const logs = await prisma.usageLog.findMany({
      where: { userId: req.user.id },
      orderBy: { createdAt: 'desc' },
      take: 100
    });

    const stats = {
      totalOutfitsGenerated: logs.filter(l => l.action === 'OUTFIT_GENERATED').length,
      totalClothingAdded: logs.filter(l => l.action === 'CLOTHING_ADDED').length,
      totalOutfitsSaved: logs.filter(l => l.action === 'OUTFIT_SAVED').length,
      recentActivity: logs.slice(0, 10)
    };

    res.json(stats);
  } catch (error) {
    console.error('Analytics error:', error);
    res.status(500).json({ error: 'Failed to get analytics' });
  }
});

// ============================================
// ERROR HANDLING
// ============================================

app.use((err, req, res, next) => {
  console.error('Unhandled error:', err);
  res.status(500).json({ error: 'Internal server error' });
});

// ============================================
// SERVER START
// ============================================

// Graceful shutdown
process.on('SIGTERM', async () => {
  console.log('SIGTERM received, shutting down...');
  await prisma.$disconnect();
  process.exit(0);
});

if (require.main === module) {
  app.listen(PORT, () => {
    console.log(`🚀 Fito Backend running on port ${PORT}`);
    console.log(`📊 Database: PostgreSQL with Prisma`);
    console.log(`💳 Payments: ${stripe ? 'Stripe enabled' : 'Stripe disabled'}`);
  });
}

module.exports = app;
