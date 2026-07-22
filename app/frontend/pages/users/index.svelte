<script>
  import { Tween } from 'svelte/motion';
  import { cubicOut } from 'svelte/easing';
  import { slide } from 'svelte/transition';
  import { signup } from '~/lib/auth.js'

  const { referrer, host } = $props()
  let percentage = new Tween(15, {
    easing: cubicOut,
    duration: 200
  })

  $effect(() => {
    // save percentage in cookie
    document.cookie = `share_percentage=${percentage.current}; path=/; max-age=31536000`
  })
</script>

<svelte:head>
  <meta name="description" content="Next-Generation Content Monetization Platform">

  <!-- Open Graph / Facebook -->
  <meta property="og:type" content="website" />
  <meta property="og:title" content="KeoScout" />
  <meta property="og:description" content="Next-Generation Content Monetization Platform" />
  <meta property="og:image" content={`${host}/preview.jpg`} />

  <!-- Twitter -->
  <meta name="twitter:card" content="summary_large_image" />
  <meta name="twitter:title" content="KeoScout" />
  <meta name="twitter:description" content="Next-Generation Content Monetization Platform" />
  <meta name="twitter:image" content={`${host}/preview.jpg`} />
</svelte:head>

<main>
  <section>
  {#if referrer}
  <p>
    <span class="text-2xl"><strong>{referrer.name}</strong> invited you to join KeoScout!</span>
  </p>
  <div class="card mt-4 text-left">
    <div class="flex items-center gap-4">
      <label for="enable_sharing" class="flex-1">
        <h3>Share your success</h3>
        <p class="hint">
          {referrer.name} will receive a share of what you earn. You can change this any time.
        </p>
      </label>
      <label class="switch" for="enable_sharing">
        <input id="enable_sharing" type="checkbox" checked={percentage.current > 0} onchange={(e) => percentage.set(e.target.checked ? 15 : 0)} />
        <span class="slider round"></span>
      </label>
    </div>
    {#if percentage.target > 0}
      <section transition:slide>
        <div class="flex">
          <p class="flex-1">Revenue share</p>
          <p>{percentage.target}%</p>
        </div>
        <input type="range" min="1" max="100" value={percentage.current} oninput={(e) => percentage.set(parseInt(e.target.value), {duration: 0})} class="w-full mt-2"/>
      </section>
      {/if}
    </div>
    <button onclick={signup} class="btn primary mt-8 mb-2">
      Create account
    </button>
  {:else}
    <div class="card mt-4">
      KeoScout is currently invite-only.
    </div>
  {/if}
  </section>
</main>

<style>
  .hero {
    font-size: 2rem;
    font-weight: bold;
    padding: 2rem 0;
    filter: drop-shadow(0 5px 5px rgba(0, 0, 0)) drop-shadow(0 0 50px rgba(183, 134, 71, 0.5));
  }

</style>