<script>
  const { current_user } = $props()
</script>

<main>
  <section>
    <h2>Invite friends</h2>
    <div class="card mt-4">
      <h3>Earn together</h3>
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