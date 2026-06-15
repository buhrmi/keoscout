<script>
import { modal } from 'inertiax-ui'
import 'inertiax-ui/dark.css'

const {
  current_user,
  referrer,
  header = true,
  footer = true,
  children
} = $props()

</script>

<svelte:head>
  <title>Keo</title>
</svelte:head>

<div class="layout">
  {#if header}
    <header>
      <section>
        <a href="/" class="logo">
          <img src="~/assets/logo.png" alt="Keo" class="h-12"/>
        </a>
      </section>
    </header>
  {/if}
  
  {@render children()}
  
  {#if footer}
    <footer>
      <section>
        <p class="text-sm text-gray-500">
          &copy; {new Date().getFullYear()} Keo Platforms.
          <a href="/terms" class="subtle">Terms of Service</a>
        </p>
      </section>
    </footer>
  {/if}

  {#if current_user}
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
  {:else if referrer}
    <nav>
      <section>
        <a href="/session/new" use:modal class="btn mt-8 mb-2">
          Get started
        </a>
      </section>
    </nav>
  {/if}
</div>

<style>
  nav menu {
    display: flex;
    justify-content: space-around;
    gap: 1rem;
    padding: 0.5rem;
  }
</style>