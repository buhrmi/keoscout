<script>
const { 
  header = true,
  footer = true,
  children
} = $props()
</script>

<svelte:head>
  <title>Keo</title>
</svelte:head>

<div class="layout">
  {#if header}
    <header>
      <section>
        <a href="/" class="logo">
          <img src="~/assets/logo.png" alt="Keo" class="h-12"/>
        </a>
      </section>
    </header>
  {/if}
  
  {@render children()}
  
  {#if footer}
    <footer>
      <section>
        <p class="text-sm text-gray-500">
          &copy; {new Date().getFullYear()} Keo Platforms.
          <a href="/terms" class="subtle">Terms of Service</a>
        </p>
      </section>
    </footer>
  {/if}
</div>