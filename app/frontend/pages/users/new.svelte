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
  <a href="" class="upload-btn mt-8 mb-2">
    Set up my profile
  </a>
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


  .upload-btn {
  display: inline-block;
  padding: 14px 32px;
  font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
  font-size: 16px;
  font-weight: 600;
  color: #ffffff;
  text-decoration: none;
  text-align: center;
  cursor: pointer;
  
  /* Metallic Gold Gradient & Border */
  background: linear-gradient(180deg, #b78647 0%, #684218 100%);
  border: 1px solid #865d2b;
  border-radius: 32px;
  
  /* 3D Drop Shadow & Inner Glow */
  box-shadow: 
    0 4px 15px rgba(0, 0, 0, 0.5), 
    inset 0 1px 1px rgba(255, 255, 255, 0.2);
  text-shadow: 0 1px 2px rgba(0, 0, 0, 0.6);
  
  /* Smooth Transition for Hover Effects */
  transition: all 0.2s ease-in-out;
}

/* Hover State (Slightly brighter, subtle lift) */
.upload-btn:hover {
  background: linear-gradient(180deg, #c79656 0%, #784d1d 100%);
  box-shadow: 
    0 6px 20px rgba(0, 0, 0, 0.6), 
    inset 0 1px 1px rgba(255, 255, 255, 0.3);
  /* transform: translateY(-1px); */
}

/* Active State (Pressed down effect) */
.upload-btn:active {
  /* transform: translateY(1px); */
  box-shadow: 
    0 2px 8px rgba(0, 0, 0, 0.6), 
    inset 0 1px 3px rgba(0, 0, 0, 0.4);
}
</style>