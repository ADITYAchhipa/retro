const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const userSchema = new mongoose.Schema({
  name: {
    type: String,
    required: true,
    trim: true,
    maxlength: 100
  },
  email: {
    type: String,
    required: true,
    unique: true,
    lowercase: true,
    trim: true
  },
  password: {
    type: String,
    minlength: 6
  },
  phone: {
    type: String,
    trim: true
  },
  avatar: {
    type: String,
    default: null
  },
  role: {
    type: String,
    enum: ['seeker', 'owner', 'admin'],
    default: 'seeker'
  },
  isVerified: {
    type: Boolean,
    default: false
  },
  authProvider: {
    type: String,
    enum: ['local', 'google', 'facebook'],
    default: 'local'
  },
  googleId: {
    type: String,
    sparse: true
  },
  facebookId: {
    type: String,
    sparse: true
  },
  address: {
    street: String,
    city: String,
    state: String,
    country: String,
    zipCode: String,
    coordinates: {
      latitude: Number,
      longitude: Number
    }
  },
  preferences: {
    currency: {
      type: String,
      default: 'USD'
    },
    language: {
      type: String,
      default: 'en'
    },
    notifications: {
      email: { type: Boolean, default: true },
      push: { type: Boolean, default: true },
      sms: { type: Boolean, default: false }
    }
  },
  profile: {
    bio: String,
    dateOfBirth: Date,
    gender: {
      type: String,
      enum: ['male', 'female', 'other', 'prefer_not_to_say']
    },
    occupation: String,
    emergencyContact: {
      name: String,
      phone: String,
      relationship: String
    }
  },
  verification: {
    email: {
      isVerified: { type: Boolean, default: false },
      token: String,
      expiresAt: Date
    },
    phone: {
      isVerified: { type: Boolean, default: false },
      code: String,
      expiresAt: Date
    },
    identity: {
      isVerified: { type: Boolean, default: false },
      documentType: String,
      documentNumber: String,
      documentImages: [String]
    }
  },
  ratings: {
    average: { type: Number, default: 0 },
    count: { type: Number, default: 0 },
    asOwner: { type: Number, default: 0 },
    asRenter: { type: Number, default: 0 }
  },
  stats: {
    totalBookings: { type: Number, default: 0 },
    totalListings: { type: Number, default: 0 },
    joinedDate: { type: Date, default: Date.now },
    lastActive: { type: Date, default: Date.now }
  },
  tokens: {
    referralCode: String,
    earnedTokens: { type: Number, default: 0 },
    spentTokens: { type: Number, default: 0 }
  },
  subscription: {
    plan: {
      type: String,
      enum: ['free', 'basic', 'premium', 'pro'],
      default: 'free'
    },
    expiresAt: Date,
    features: [String]
  },
  isActive: {
    type: Boolean,
    default: true
  },
  lastLogin: {
    type: Date,
    default: Date.now
  }
}, {
  timestamps: true,
  toJSON: { virtuals: true },
  toObject: { virtuals: true }
});

// Indexes
userSchema.index({ email: 1 });
userSchema.index({ googleId: 1 }, { sparse: true });
userSchema.index({ facebookId: 1 }, { sparse: true });
userSchema.index({ 'tokens.referralCode': 1 }, { sparse: true });

// Virtual for full name
userSchema.virtual('fullName').get(function() {
  return this.name;
});

// Hash password before saving
userSchema.pre('save', async function(next) {
  if (!this.isModified('password')) return next();
  
  if (this.password) {
    this.password = await bcrypt.hash(this.password, 12);
  }
  next();
});

// Compare password method
userSchema.methods.comparePassword = async function(candidatePassword) {
  if (!this.password) return false;
  return bcrypt.compare(candidatePassword, this.password);
};

// Generate referral code
userSchema.methods.generateReferralCode = function() {
  if (!this.tokens.referralCode) {
    this.tokens.referralCode = `REF${this._id.toString().slice(-8).toUpperCase()}`;
  }
  return this.tokens.referralCode;
};

// Update last active
userSchema.methods.updateLastActive = function() {
  this.stats.lastActive = new Date();
  return this.save();
};

module.exports = mongoose.model('User', userSchema);
