<script>
  const { current_user } = $props()
</script>

<main>
  <section class="text-center place-items-center">
    <img src="~/assets/logo-gold.png" class="w-60% mb-4" alt="">
    <p>The easiest way to earn money with your content</p>
    
    <div class="card mt-4 text-center">
      <h2>Earn together</h2>
      <p>Share this code with friends to invite them to Keo and start earning together.</p>
      <img class="inline-block mt-4" src="https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=https://keoscout.com?scout_id={current_user.id}" alt="QR code"/>
    </div>
  </section>
</main>
