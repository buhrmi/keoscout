<script>
  import Default from './default.svelte'
  const { children } = $props()
</script>

<svelte:head>
  <title>Keo</title>
</svelte:head>

<Default header={false} {children} />