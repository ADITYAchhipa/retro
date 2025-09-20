import { useState, useRef, useEffect } from 'react'
import { ChevronDownIcon, GlobeAltIcon } from '@heroicons/react/24/outline'
import { useCountryStore, countries, Country } from '@/stores/countryStore'

export default function CountrySelector() {
  const [isOpen, setIsOpen] = useState(false)
  const { selectedCountry, setSelectedCountry } = useCountryStore()
  const dropdownRef = useRef<HTMLDivElement>(null)

  useEffect(() => {
    const handleClickOutside = (event: MouseEvent) => {
      if (dropdownRef.current && !dropdownRef.current.contains(event.target as Node)) {
        setIsOpen(false)
      }
    }

    document.addEventListener('mousedown', handleClickOutside)
    return () => document.removeEventListener('mousedown', handleClickOutside)
  }, [])

  const handleCountrySelect = (country: Country) => {
    setSelectedCountry(country)
    setIsOpen(false)
  }

  return (
    <div className="relative" ref={dropdownRef}>
      <button
        onClick={() => setIsOpen(!isOpen)}
        className="flex items-center space-x-2 bg-white border border-gray-300 rounded-lg px-3 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
      >
        <GlobeAltIcon className="h-4 w-4 text-gray-500" />
        <span className="text-lg">{selectedCountry.flag}</span>
        <span className="hidden sm:inline">{selectedCountry.name}</span>
        <span className="sm:hidden">{selectedCountry.code}</span>
        <ChevronDownIcon className={`h-4 w-4 text-gray-500 transition-transform ${isOpen ? 'rotate-180' : ''}`} />
      </button>

      {isOpen && (
        <div className="absolute right-0 mt-2 w-64 bg-white border border-gray-200 rounded-lg shadow-lg z-50 max-h-80 overflow-y-auto">
          <div className="p-2">
            <div className="text-xs font-medium text-gray-500 uppercase tracking-wider px-3 py-2">
              Select Country/Region
            </div>
            {countries.map((country) => (
              <button
                key={country.code}
                onClick={() => handleCountrySelect(country)}
                className={`w-full flex items-center space-x-3 px-3 py-2 text-sm rounded-md hover:bg-gray-100 ${
                  selectedCountry.code === country.code ? 'bg-blue-50 text-blue-700' : 'text-gray-900'
                }`}
              >
                <span className="text-lg">{country.flag}</span>
                <div className="flex-1 text-left">
                  <div className="font-medium">{country.name}</div>
                  <div className="text-xs text-gray-500">{country.currency} • {country.code}</div>
                </div>
                {selectedCountry.code === country.code && (
                  <div className="w-2 h-2 bg-blue-600 rounded-full"></div>
                )}
              </button>
            ))}
          </div>
        </div>
      )}
    </div>
  )
}
