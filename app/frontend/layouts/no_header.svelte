<script>
  import Default from './default.svelte'
  const props = $props()
</script>

<svelte:head>
  <title>Keo</title>
</svelte:head>

<Default header={false} {...props} />