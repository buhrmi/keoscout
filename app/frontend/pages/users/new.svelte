<script>
  import { inertia } from 'inertiax-svelte'
  import { Tween } from 'svelte/motion';
  import { cubicOut } from 'svelte/easing';

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
  <img class="w-1/2 max-w-80 mx-auto pt-20 mb-4" src="~/assets/logo-gold.png" alt="Keo logo"/>
  <p>
    <!-- 0 VND paid out to creators so far. <br> -->
    The easiest way to earn money with your photos.
  </p>
  {#if scout}
  <div class="card mt-4">
    <p class="text-2xl">🎉 🎉 🎉</p>
    <p>

      <span class="text-xl"><strong>{scout.name}</strong> has invited you to join Keo!</span><br>Set a percentage of revenue
      that you would like to share with them. Don't worry, you can change this any time.
    </p>
    <p class="text-2xl">{percentage.target}%</p>
    <input type="range" min="0" max="100" value={percentage.current} oninput={(e) => percentage.set(parseInt(e.target.value), {duration: 0})} class="w-full mt-4"/>
    <button onclick={() => percentage.set(0)} class="btn mt-4">
      0%
    </button>
    <button onclick={() => percentage.set(15)} class="btn mt-4">
      15% (recommended)
    </button>
    <button onclick={() => percentage.set(50)} class="btn mt-4">
      50%
    </button>
  </div>
  {/if}
  <a href="" class="btn mt-8 mb-2">
    + Upload your first photo
  </a><br>
  or
  <a use:inertia href="/dashboard" >continue to dashboard</a>
</main>
