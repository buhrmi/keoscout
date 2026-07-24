<script>
  import { authenticate } from '~/lib/auth.js'
</script>

<div class="divider">or</div>
<button class="btn secondary" onclick={() => authenticate('zalo')}>
  <img src={"/vendor/zalo.svg"} alt="Zalo" class="h-6"/>
  Continue with Zalo
</button>
