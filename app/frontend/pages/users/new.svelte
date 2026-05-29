<script>
  import { inertia } from '@inertiajs/svelte'
  import { Tween } from 'svelte/motion';
  import { cubicOut } from 'svelte/easing';
  import { slide } from 'svelte/transition';

  const { scout } = $props()
  let percentage = new Tween(15, {
    easing: cubicOut,
    duration: 200
  })

  $effect(() => {
    // save percentage in cookie
    document.cookie = `share_percentage=${percentage.current}; path=/; max-age=31536000`
  })
</script>

<main class="text-center">
  <img class="logo w-2/3 max-w-80 mx-auto pt-8 mb-4" src="~/assets/logo-gold.png" alt="Keo logo"/>
  <p class="mb-8">
    <!-- 0 VND paid out to creators so far. <br> -->
    The easiest way to turn talent into revenue
  </p>
  {#if scout}
  <p>
    <span class="text-xl"><strong>{scout.name}</strong> has invited you!</span>
  </p>
  <div class="card mt-4 text-left">
    <div class="flex items-center gap-4">
      <label for="enable_sharing" class="flex-1">
        <h3>Automatically share revenue</h3>
        <p class="hint">
          {scout.name} will receive a percentage of what you earn. You can change this any time.
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
          <p class="flex-1">Revenue split</p>
          <p>{percentage.target}%</p>
        </div>
        <input type="range" min="1" max="100" value={percentage.current} oninput={(e) => percentage.set(parseInt(e.target.value), {duration: 0})} class="w-full mt-2"/>
      </section>
    {/if}
  </div>
  <a href="" class="btn mt-8 mb-2">
    + Upload your first photo
  </a><br>
  or
  <a use:inertia href="/dashboard" >continue to dashboard</a>
  {:else}
  <div class="card mt-4">
    Keo is currently invite-only.
  </div>
  {/if}
</main>


<style>
  .logo {
    filter: drop-shadow(0 5px 5px rgba(0, 0, 0));
  }
</style>