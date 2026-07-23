<script>
  import { modal } from 'inertiax-ui'
  import { Toaster } from 'svelte-sonner'
  import '~/assets//modal.css'
  import { currentUser } from '~/stores/user.svelte.js'

  const {
    footer = true,
    referrer,
    children
  } = $props()
</script>

<svelte:head>
  <title>KeoScout</title>
</svelte:head>

<div class="layout">
  <div class="sidebar">
    <header>
      
      <a href="/" class="logo">
        <img src="~/assets/logo.png" alt="Keo" class="h-12"/>
      </a>
    </header>
    
    {#if $currentUser}
      <nav>


        <a href="/dashboard" class="action">
          <div class="btn-circle">
            <div class="i-mdi:home text-2xl"></div>
          </div>
          <p>
            Home
          </p>
        </a>

        <a use:modal href="/dashboard/posts/new" class="action">
          <div class="btn-circle">
            <div class="i-mdi:plus text-2xl"></div>
          </div>
          <p>
            New Post
          </p>
        </a>

        <a href="/dashboard/friends" class="action">
          <div class="btn-circle">
            <div class="i-mdi:account-group text-2xl"></div>
          </div>
          <p>
            Friends
          </p>
        </a>


      </nav>

      <menu>
        <p>
          <a href="/session" data-method="delete">Log out</a>
        </p>
      </menu>
    {/if}
  </div>
  
  {@render children()}
  
  {#if footer}
    <footer>
      <section>
        <p class="text-sm text-gray-500">
          &copy; {new Date().getFullYear()} Keo Platforms.
          <a href="/terms">Terms of Service</a>
        </p>
      </section>
    </footer>
  {/if}
</div>

<Toaster theme="dark" richColors position="top-right" />

<style>
  nav {
    display: flex;
    justify-content: space-around;
    gap: 1rem;
    padding: var(--padding);
    @media (min-width: 600px) {
      flex-direction: column;
      justify-content: start;
      align-items: start;
      flex: 1;
    }
  }

  header, menu {
    border-bottom: 1px solid var(--color-border);
    padding: var(--padding);
    background: #0003;
    backdrop-filter: blur(10px);
    display: flex;
    justify-content: center;
  }
  
  menu {
    display: flex;
    justify-content: end;
    align-items: center;
    @media (min-width: 600px) {
      border-bottom: none;
      justify-content: center;
    }
  }

  .action {
    font-weight: normal;
    display: inline-flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;

    p {
      font-size: 0.75rem;
    }
    @media (min-width: 600px) {
      flex-direction: row;
      gap: 0.5rem;
    }
  }
</style>