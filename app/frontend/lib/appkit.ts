// lib/appkit.ts
import { BROWSER } from 'esm-env'
import { createAppKit } from '@reown/appkit'
import { WagmiAdapter } from '@reown/appkit-adapter-wagmi'
import { arbitrum, mainnet } from '@reown/appkit/networks'

// Only initialize in browser environment
let appKit: ReturnType<typeof createAppKit> | undefined = undefined

if (BROWSER) {
  const projectId = "e33aa1da8587ce34b08b7945752bbfac"

  const networks = [arbitrum, mainnet]

  // Create adapter
  const wagmiAdapter = new WagmiAdapter({
    networks,
    projectId
  })

  // Initialize AppKit
  appKit = createAppKit({
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
  })
}

export { appKit }