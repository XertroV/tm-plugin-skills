# Issue tracker

Issues live in [XertroV/tm-plugin-skills](https://github.com/XertroV/tm-plugin-skills/issues).

## Wayfinding operations

The map is an issue labelled `wayfinder:map`. Decision tickets are sub-issues labelled with exactly one type:

- `wayfinder:research`
- `wayfinder:prototype`
- `wayfinder:grilling`
- `wayfinder:task`

Use GitHub's native sub-issue and dependency relationships. Assignment is the claim: an open, unassigned, unblocked sub-issue is on the frontier.

### Read the map and frontier

```bash
gh issue list --repo XertroV/tm-plugin-skills --label wayfinder:map --state open
gh issue view <map-number> --repo XertroV/tm-plugin-skills --comments
gh issue list --repo XertroV/tm-plugin-skills --state open --json number,title,url,assignees,labels
```

Confirm blocking and parentage in the GitHub issue UI or through GitHub's sub-issues/dependencies API before claiming.

### Claim

```bash
gh issue edit <ticket-number> --repo XertroV/tm-plugin-skills --add-assignee XertroV
```

Claim before reading deeply or doing ticket work. Concurrent sessions skip assigned tickets.

### Resolve

1. Post the answer as a resolution comment.
2. Close the decision ticket.
3. Append one linked-title gist to the map's **Decisions so far**.
4. Create newly-specifiable tickets, attach them as sub-issues, and wire native blocking edges.
5. Remove graduated material from **Not yet specified**.

The full decision belongs in the ticket; the map remains a low-resolution index.
