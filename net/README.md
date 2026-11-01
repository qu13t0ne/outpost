# net/ - access policy templates

Templates for the overlay's access policy. This directory holds the shape of the rule, never
a deployed rule set.

## Why this directory exists

The exposure model in [`../docs/exposure-model.md`](../docs/exposure-model.md) splits the
overlay by device class and names this directory as where the policy is authored. Until this
directory existed that reference pointed at nothing, which meant the centrepiece of the model
was a paragraph with no artifact behind it.

## Files

| File | What it is |
| ---- | ---------- |
| `tailscale-policy.hujson` | Device-class policy as a template. Four tags, three classes, first-match-wins, deny by omission |

## Substitution rules

The template uses class names, not device names. Substituting it for a real deployment means
adding the estate's own devices to the classes it defines. That substitution belongs in the
private notes of whoever runs the estate, for two reasons: device names identify people and
places, and a policy file that is copied wholesale instead of read is how an allow-all default
survives a migration that was supposed to remove it.

What may be committed here:

- Tag class names and what each class is for.
- The rule structure, the ordering logic, and the intent tests.
- Placeholder addresses from the documentation ranges, if an example needs one.

What must never be committed here:

- Real device names, hostnames, tailnet names, or account identifiers.
- Real subnets or addresses outside the documentation ranges.
- Anything that identifies whose estate this is.

## Validation

```sh
tailscale debug validate net/tailscale-policy.hujson
```

Run it after every substitution and after every edit here. The `tests` array in the file is
intent, not enforcement: it fails a validation run when the policy stops saying what it is
meant to say.

## The rule that matters most

Denial is the absence of a line. There is no deny action to write.

That has one practical consequence worth stating plainly: a policy that accepts too much does
not look broken. It looks like a policy. The most common way the device-class split is lost is
a single wildcard source or a member-wide accept added during a debugging session and never
removed. The intent tests exist to catch exactly that.
