<script>
  import { currentUser } from '~/stores/user.svelte.js'
  import { Form } from 'inertiax-svelte'
  import Input from '~/lib/forms/Input.svelte'
  import Socials from './_socials.svelte'

  // const form = useForm({ email: '', password: '' })

  const { close } = $props()

  $effect(() => $currentUser && close(false))
</script>

<main>
  <section>
    <p>
      Welcome back!
    </p>
    <Form action="/session" method="post" options={{frame: "_top"}}>
      {#snippet children({ errors })}
        <Input name="email" label="Email" {errors} />
        <Input name="password" label="Password" type="password" {errors} />
        <button class="btn primary w-full" type="submit">
          Sign in
        </button>
      {/snippet}
    </Form>
    <Socials />
  </section>
</main>

