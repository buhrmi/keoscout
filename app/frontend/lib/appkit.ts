// lib/appkit.ts
import { BROWSER } from 'esm-env'
import { createAppKit } from '@reown/appkit'
import { WagmiAdapter } from '@reown/appkit-adapter-wagmi'
import { arbitrum, mainnet } from '@reown/appkit/networks'
import { writable, get } from 'svelte/store'

// Only initialize in browser environment
export const appKit = writable<ReturnType<typeof createAppKit> | undefined>(undefined)

if (BROWSER) {
  const projectId = "e33aa1da8587ce34b08b7945752bbfac"

  const networks = [arbitrum, mainnet]

  // Create adapter
  const wagmiAdapter = new WagmiAdapter({
    networks,
    projectId
  })

  // Initialize AppKit
  appKit.set(createAppKit({
    adapters: [wagmiAdapter],
    networks: [arbitrum, mainnet],
    defaultNetwork: arbitrum,
    projectId,
    metadata: {
      name: 'KeoScout',
      description: 'The crypto-native creator network.',
      url: 'https://www.keoscout.com',
      icons: ['https://github.com/buhrmi/keoscout/blob/main/public/touch-icon.png?raw=true']
    }
  }))
}

export function login() {
  const $appKit = get(appKit)
  if ($appKit) {
    $appKit.open()
  } else {
    console.error('AppKit is not initialized yet.')
  }
}