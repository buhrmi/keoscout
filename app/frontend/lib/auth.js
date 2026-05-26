export function login(provider) {
  if (import.meta.env.MODE == 'production') return alert("Coming soon")
  
  const width = 500;
  const height = 600;
  const left = (screen.width - width) / 2;
  const top = (screen.height - height) / 2;
  const windowFeatures = `width=${width},height=${height},left=${left},top=${top}`;
  
  window.open(`/session/new?provider=${provider}`, 'login', windowFeatures);
}