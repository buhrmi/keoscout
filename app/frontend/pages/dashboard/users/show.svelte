<script>
  import { inertia } from 'inertiax-svelte'
  import { router } from 'inertiax-svelte'

</script>

<main>
  <section>
    <div class="text-center pt-8 pb-16">
      <p>Account Balance</p>
      <h2>VND 0</h2>
    </div>
  </section>
  <section>
    <div class="card">
      <h3>🎉 Welcome to Keo</h3>
      <p>
        Set up your profile to get started.
      </p>
      <a use:inertia href="/dashboard/user/edit" class="btn w-full mt-4">
        Set up profile
      </a>
    </div>
  </section>
  
</main>

