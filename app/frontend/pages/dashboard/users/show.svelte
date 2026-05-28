<script>
  import { inertia } from 'inertiax-svelte'
</script>

<main>
  <section>
    <div class="card">
      <p>Account Balance</p>
      <h2>VND 0</h2>
    </div>
    
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

