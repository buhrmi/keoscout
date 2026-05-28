<script>
  import { router } from 'inertiax-svelte'
  const { current_user, test } = $props()
  function back(ev) {
    // TODO: only call history.back() if we stay on the same origin
    history.back()
    ev.preventDefault()
  }
  function testbtn() {
    router.push({
      replace: false,
      props: (currentProps, onceProps) => ({ ...currentProps, ...onceProps, test: 'test' })
    })
  }
</script>

<main>
  <section>
    <a onclick={back} href="/dashboard" class="btn-circle">
      <div class="i-mdi:arrow-back text-xl">Back</div>
    </a>
  </section>
  <section>
    <h2>Earn together</h2>
    <div class="card mt-4">
      <h3>Invite friends</h3>
      <p>
        Your friends can set a percentage of their earnings to share with you.
      </p>
    </div>
    <div class="card mt-4 text-center">
      <h3 class="mb-4">
        Your QR code
      </h3>
      <img class="inline-block" src="https://api.qrserver.com/v1/create-qr-code/?size=150x150&data=https://keoscout.com?scout_id={current_user.id}" alt="QR code"/>
    </div>
  </section>
</main>

<button onclick={testbtn}>
  sfasdf {test}
</button>