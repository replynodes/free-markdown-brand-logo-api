# Clearbit Logo API migration

For the basic domain-to-image URL pattern, replace:

```text
https://logo.clearbit.com/stripe.com
```

with:

```text
https://img.replynodes.com/stripe.com
```

The ReplyNodes endpoint is a public image URL and is not a claim of Clearbit parameter compatibility or broader feature parity. A successful response may be a placeholder; check `x-replynodes-logo-fallback` when your UI needs to distinguish that case.
