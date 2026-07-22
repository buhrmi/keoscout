<script>
  import { authenticate } from '~/lib/auth.js'
</script>

<div class="divider">or</div>
<button class="btn outline" onclick={() => authenticate('zalo')}>
  Continue with Zalo
</button>

<style>
  .divider {
    display: grid;
    grid-template-columns: 1fr auto 1fr;
    align-items: center;
    gap: 1rem;
    margin: 1rem 0;
    color: #888;
  }

  .divider::before,
  .divider::after {
    content: '';
    display: block;
    height: 1px;
    background: var(--color-border);
  }
</style>