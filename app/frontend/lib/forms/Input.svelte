<script>
  const { 
    name, 
    errors,
    label,
    ...rest } = $props()
  let error = $derived(errors[name])
</script>

<div class="field" class:error>
  <label for={name}>
    {label}
    {#if error}
      <span class="error">{error}</span>
    {/if}
  </label>
  <input name={name} placeholder="" onfocus={() => error = null} {...rest}/>
</div>