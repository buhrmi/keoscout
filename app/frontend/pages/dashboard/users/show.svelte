<script>
  import { inertia } from '@inertiajs/svelte'
  import { router } from '@inertiajs/svelte'

</script>

<main>
  <section>
    <div class="text-center py-24">
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
  <section>
    
    <div class="actions mt-4">
      <a use:inertia href="/dashboard/friends/new" class="action">
        <div class="btn-circle">
          <div class="i-mdi:user-add text-2xl"></div>
        </div>
        <p>
          Invite
        </p>
      </a>
    </div>
  </section>
  
</main>

