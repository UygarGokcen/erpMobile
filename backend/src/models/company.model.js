const mongoose = require('mongoose');

const companySchema = new mongoose.Schema({
  name: {
    type: String,
    required: true,
    trim: true
  },
  address: {
    street: String,
    city: String,
    state: String,
    country: String,
    postalCode: String
  },
  phone: String,
  email: {
    type: String,
    required: true,
    trim: true,
    lowercase: true
  },
  taxNumber: {
    type: String,
    required: true,
    unique: true
  },
  industry: String,
  employees: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  }],
  settings: {
    currency: {
      type: String,
      default: 'USD'
    },
    timezone: {
      type: String,
      default: 'UTC'
    },
    fiscalYearStart: {
      type: Date,
      default: new Date(new Date().getFullYear(), 0, 1) // 1 Ocak
    }
  }
}, {
  timestamps: true
});

const Company = mongoose.model('Company', companySchema);
module.exports = Company;
