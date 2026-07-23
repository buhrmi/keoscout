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
  <header>
    <menu>
      <a href="/" class="logo">
        <img src="~/assets/logo.png" alt="Keo" class="h-12"/>
      </a>
      {#if $currentUser}
        <p>
          <a href="/session" data-method="delete">Log out</a>
        </p>
      {/if}
    </menu>
  </header>
  
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

  {#if $currentUser}
    <nav>
      <menu>
        <li>
          <a href="/dashboard" class="action">
            <div class="btn-circle">
              <div class="i-mdi:home text-2xl"></div>
            </div>
            <p>
              Home
            </p>
          </a>
        </li>
        <li>
          <a use:modal href="/dashboard/posts/new" class="action">
            <div class="btn-circle">
              <div class="i-mdi:plus text-2xl"></div>
            </div>
            <p>
              New Post
            </p>
          </a>
        </li>
        <li>
          <a href="/dashboard/friends" class="action">
            <div class="btn-circle">
              <div class="i-mdi:account-group text-2xl"></div>
            </div>
            <p>
              Friends
            </p>
          </a>
        </li>
      </menu>
    </nav>
  {/if}
</div>

<Toaster theme="dark" richColors position="top-right" />

<style>
  nav menu {
    display: flex;
    justify-content: space-around;
    gap: 1rem;
    padding: 0.5rem;
  }

  header {
    border-bottom: 1px solid var(--color-border);
    padding: var(--padding);
    background: #0003;
    backdrop-filter: blur(10px);
    menu {
      display: flex;
      justify-content: space-between;
      align-items: center;
    }

  }
</style>