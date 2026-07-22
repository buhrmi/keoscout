import { createModal } from 'inertiax-ui'

export function login() {
  const close = createModal({
    src: '/session/new',
  })
}

export function signup() {
  const close = createModal({
    src: '/users/new',
  })
}

export function authenticate(provider) {
  const width = 500;
  const height = 600;
  const left = (screen.width - width) / 2;
  const top = (screen.height - height) / 2;
  const windowFeatures = `width=${width},height=${height},left=${left},top=${top}`;
  
  window.open(`/session/new?provider=${provider}`, 'login', windowFeatures);
}