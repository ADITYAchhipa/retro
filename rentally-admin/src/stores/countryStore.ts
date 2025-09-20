import { create } from 'zustand'

export interface Country {
  code: string
  name: string
  flag: string
  currency: string
  timezone: string
}

export const countries: Country[] = [
  { code: 'ALL', name: 'All Countries', flag: '🌍', currency: 'USD', timezone: 'UTC' },
  { code: 'US', name: 'United States', flag: '🇺🇸', currency: 'USD', timezone: 'America/New_York' },
  { code: 'CA', name: 'Canada', flag: '🇨🇦', currency: 'CAD', timezone: 'America/Toronto' },
  { code: 'GB', name: 'United Kingdom', flag: '🇬🇧', currency: 'GBP', timezone: 'Europe/London' },
  { code: 'DE', name: 'Germany', flag: '🇩🇪', currency: 'EUR', timezone: 'Europe/Berlin' },
  { code: 'FR', name: 'France', flag: '🇫🇷', currency: 'EUR', timezone: 'Europe/Paris' },
  { code: 'AU', name: 'Australia', flag: '🇦🇺', currency: 'AUD', timezone: 'Australia/Sydney' },
  { code: 'JP', name: 'Japan', flag: '🇯🇵', currency: 'JPY', timezone: 'Asia/Tokyo' },
  { code: 'IN', name: 'India', flag: '🇮🇳', currency: 'INR', timezone: 'Asia/Kolkata' },
  { code: 'BR', name: 'Brazil', flag: '🇧🇷', currency: 'BRL', timezone: 'America/Sao_Paulo' },
  { code: 'MX', name: 'Mexico', flag: '🇲🇽', currency: 'MXN', timezone: 'America/Mexico_City' },
  { code: 'ES', name: 'Spain', flag: '🇪🇸', currency: 'EUR', timezone: 'Europe/Madrid' },
  { code: 'IT', name: 'Italy', flag: '🇮🇹', currency: 'EUR', timezone: 'Europe/Rome' },
  { code: 'NL', name: 'Netherlands', flag: '🇳🇱', currency: 'EUR', timezone: 'Europe/Amsterdam' },
  { code: 'SE', name: 'Sweden', flag: '🇸🇪', currency: 'SEK', timezone: 'Europe/Stockholm' },
  { code: 'SG', name: 'Singapore', flag: '🇸🇬', currency: 'SGD', timezone: 'Asia/Singapore' },
  { code: 'AE', name: 'UAE', flag: '🇦🇪', currency: 'AED', timezone: 'Asia/Dubai' },
  { code: 'ZA', name: 'South Africa', flag: '🇿🇦', currency: 'ZAR', timezone: 'Africa/Johannesburg' }
]

interface CountryStore {
  selectedCountry: Country
  setSelectedCountry: (country: Country) => void
  getCountryByCode: (code: string) => Country | undefined
  formatCurrency: (amount: number, countryCode?: string) => string
}

export const useCountryStore = create<CountryStore>((set, get) => ({
  selectedCountry: countries[0], // Default to 'All Countries'
  
  setSelectedCountry: (country: Country) => set({ selectedCountry: country }),
  
  getCountryByCode: (code: string) => countries.find(c => c.code === code),
  
  formatCurrency: (amount: number, countryCode?: string) => {
    const country = countryCode ? 
      get().getCountryByCode(countryCode) : 
      get().selectedCountry

    if (!country || country.code === 'ALL') {
      return new Intl.NumberFormat('en-US', {
        style: 'currency',
        currency: 'USD',
        minimumFractionDigits: 0,
        maximumFractionDigits: 0
      }).format(amount)
    }

    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: country.currency,
      minimumFractionDigits: 0,
      maximumFractionDigits: 0
    }).format(amount)
  }
}))
