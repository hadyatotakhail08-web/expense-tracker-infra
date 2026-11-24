# expense-tracker-infra — the AWS infrastructure, written as code

This repo holds the Terraform that defines everything my [expense-tracker app](https://github.com/hadyatotakhail08-web/expense-tracker) needs on AWS. Instead of creating a server by clicking around the AWS console (and forgetting what I clicked), the whole setup lives in files: versioned, reviewable, and rebuildable from scratch in minutes.

**For non-engineers:** "infrastructure as code" means describing servers, firewalls and permissions in text files, and letting a tool (Terraform) create and update them from those files. If a file says "one server, SSH open to my IP only, HTTPS open to the world", that's exactly what gets built, every time — no console archaeology.

## What these files create

| What | Details |
| --- | --- |
| One EC2 server | Ubuntu 24.04, image ID looked up with `describe-images` (not copied from a tutorial) |
| Security groups ("firewall rules") | SSH open only to my IP; HTTPS open; HTTP only to redirect to HTTPS |
| IAM permissions | the server can read exactly one AWS Secrets Manager secret, and nothing else |
| AWS budget | $10/month, emails me at 80% — I pay for this myself, so cost is a feature, not homework |
| Tags on every resource | so "what is this and what does it cost?" has an answer later |
| Dev and prod | same code, different values (`environments/dev.tfvars`, `environments/prod.tfvars`) |

## State, and why you'll never find it in this repo

Terraform remembers what it created in a "state file". Mine lives in an S3 bucket with locking on (`use_lockfile = true`), so two runs can't change the same infrastructure at once. It never goes in git, because state files can contain secrets in plain text — the `.gitignore` in this repo blocks `*.tfstate` on principle.

## Drift detection — I broke it on purpose to prove it works

"Drift" is when reality stops matching the code (something changed outside Terraform). I tested this deliberately:

1. Stopped and started the instance from the console, so AWS gave it a new public IP — reality now disagreed with the code.
2. `terraform plan` reported exactly which values had drifted and how.
3. `terraform apply` put everything back to what the files describe.

That's the whole point of infrastructure as code: **the files win, not the console.**

## Mistakes I made here (kept on purpose — they taught me the most)

- A placeholder bucket name (`YOUR-BUCKET-NAME`) survived into `main.tf` and broke `terraform init`. Habit formed: read every file back before planning, not just the one I was editing.
- A budget block appended from the terminal landed twice and broke the file. Habit formed: edit config in an editor, not with shell appends.
- Before making this repo public I ran the classic secret check — `git log -p | grep -iE "password|AKIA|BEGIN"` — to be certain no key or password ever entered this repo's history. Only safe references (ARNs) were found. I checked, rather than assumed.

## Using it

```
terraform init
terraform plan -var-file=environments/dev.tfvars
terraform apply -var-file=environments/dev.tfvars
```

## The other repos in this platform

- [expense-tracker](https://github.com/hadyatotakhail08-web/expense-tracker) — the app, CI/CD and monitoring
- [expense-tracker-ansible](https://github.com/hadyatotakhail08-web/expense-tracker-ansible) — the Ansible server automation
