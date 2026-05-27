<script>
  import { inertia } from '@inertiajs/svelte'
</script>

<main class="text-center">
  <img class="w-1/2 max-w-80 mx-auto pt-20 mb-4" src="~/assets/logo-gold.png" alt="Keo logo"/>
  <p>
    The easiest way to earn money with your photos.
  </p>
  <a href="" class="btn mt-8 mb-2">
    + Upload your first photo
  </a><br>
  or
  <a use:inertia href="/dashboard" >go to dashboard</a>
</main>
