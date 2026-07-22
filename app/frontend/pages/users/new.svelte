<script>
  import { authenticate } from '~/lib/auth.js'
  import { currentUser } from '~/stores/user.svelte.js'
  import { Form } from 'inertiax-svelte'
  import Input from '~/lib/forms/Input.svelte'
  import Socials from '~/pages/sessions/_socials.svelte'
  // const form = useForm({ email: '', password: '' })

  const { close } = $props()

  $effect(() => $currentUser && close(false))
</script>

<main>
  <section>
    <p>
      Let's create your account
    </p>
    <Form action="/users" method="post">
      {#snippet children({ errors })}
        <Input name="user.email" label="Email" {errors} />
        <Input name="user.password" label="Password" type="password" {errors} />
        <button class="btn primary w-full" type="submit">
          Create account
        </button>
      {/snippet}
    </Form>
    <a href="/session/new" data-replace class="text-right pt-4">Already have an account? Sign in</a>
    <Socials />
  </section>
</main>


