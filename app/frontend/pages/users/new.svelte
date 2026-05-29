<script>
  import { inertia } from 'inertiax-svelte'
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
  <img class="w-1/2 max-w-80 mx-auto pt-20 mb-4" src="~/assets/logo-gold.png" alt="Keo logo"/>
  <p>
    <!-- 0 VND paid out to creators so far. <br> -->
    The easiest way to earn money with your photos.
  </p>
  {#if scout}
  <p class="text-2xl">🎉 🎉 🎉</p>
  <p>
    <span class="text-xl"><strong>{scout.name}</strong> has invited you to join Keo!</span>
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

/* The switch - the box around the slider */
.switch {
  --height: 24px;
  position: relative;
  display: inline-block;
  height: var(--height);
  width: calc(var(--height) * 2 - 8px);
}

/* Hide default HTML checkbox */
.switch input {
  opacity: 0;
  width: 0;
  height: 0;
}

/* The slider */
.slider {
  position: absolute;
  cursor: pointer;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background-color: #ccc;
  -webkit-transition: .4s;
  transition: .4s;
  border-radius: var(--height);
}

.slider:before {
  position: absolute;
  content: "";
  height: calc(var(--height) - 8px);
  width: calc(var(--height) - 8px);
  left: 4px;
  bottom: 4px;
  background-color: white;
  -webkit-transition: .4s;
  transition: .4s;
  border-radius: 50%;
}

input:checked + .slider {
  background-color: #2196F3;
}

input:focus + .slider {
  box-shadow: 0 0 1px #2196F3;
}

input:checked + .slider:before {
  -webkit-transform: translateX(calc(var(--height) - 8px));
  -ms-transform: translateX(calc(var(--height) - 8px));
  transform: translateX(calc(var(--height) - 8px));
}
</style>