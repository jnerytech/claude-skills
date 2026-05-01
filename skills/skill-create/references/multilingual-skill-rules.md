# Multilingual Skill Authoring Rules

Compiled from four reference articles into seven practical blocks. Where articles disagreed, the more conservative position is taken.

## 1. Frontmatter must always be English — not aesthetics, routing

This is the strongest and most consensual recommendation across the four articles. The YAML frontmatter `name` and `description` fields are the **only** content of a skill that enters the system prompt during discovery (Level 1). Current limit: 1,536 characters per skill (recently raised from 250).

The model decides whether to activate a skill via an LLM forward pass — **without** embeddings, classifiers, or regex. That means every word in `description` competes directly with the model's training memory, estimated at 38.8% English, 57.5% code, and only 3.7% other languages. Skills with PT-BR frontmatter show invocation rates fluctuating between 6% and 66%; in English, close to 100%.

Concrete rules:

- `name`: lowercase, digits, and hyphens only (the agentskills.io spec already blocks accents — this is a technical constraint, not a preference).
- `description`: always third person (the official doc says "inconsistent point-of-view causes discovery problems").
- Open with "Use when..." or "Used to..." — English imperative verbs are recognized as triggers.
- Embed **PT-BR triggers as quoted phrases inside the English description**. Example: `Use when the user asks to "refactor data layer" or mentions "padrão repository"`. This preserves English discovery while capturing PT-BR user queries.
- Avoid `<` and `>` in frontmatter values — they can inject unintended instructions.

## 2. SKILL.md body — PT-BR acceptable with structural caveats

The body loads only when the skill activates (Level 2). The trade-off shifts here: readability for the author offsets the small comprehension gap (~2-3 points on Sonnet/Opus). But four islands must remain English even inside a PT-BR skill:

**(a) Critical Rules / negative restrictions.** The M-IFEval benchmark and CAPITU show greater multilingual degradation precisely on restrictive and conditional instructions. "Do NOT use for X" is more reliable than "Não use para X". Keep blocks like `## Critical Rules` or `## Common Gotchas` in English even inside PT-BR skills.

**(b) Adherence imperatives.** "MUST", "IMPORTANT", "YOU MUST", "NEVER" work more consistently than "DEVE", "OBRIGATÓRIO", "NUNCA". The PT-BR equivalents work, but with reduced reliability.

**(c) Canonical technical terms.** Function names, shell commands, parameters, API identifiers. Mixing `executar git rebase --interactive no branch principal` is better than trying to translate commands. Same applies to terms like RAG, embedding, hook, MCP — keep as-is.

**(d) Numbered logic with hard dependencies.** To avoid **Step Skipping** (the model skips steps it considers redundant), number steps and use explicit English locks: `Do NOT proceed to step 4 until step 3 returns results`. This punitive control pattern is recognized by the model far more rigidly than the equivalent PT-BR prose.

Limit: the official doc recommends keeping SKILL.md below 500 lines. For PT-BR this is even more critical due to the token tax.

## 3. Mitigating Step Skipping and Enum Guessing

Two failure patterns are especially sensitive on Opus 4.7 (which obeys literally):

**Step Skipping.** Skills written as fluid PT-BR prose are interpreted by the model as optimizable suggestions. A `"Após resolver a pesquisa, enriqueça os dados e então salve o arquivo"` allows the model to skip enrichment. Mitigation: skills must resemble computational assembly logic, not manuals. Number explicitly, declare dependencies in English, use imperative verbs.

**Enum Guessing.** In integrations with MCPs that expect strict values (e.g. `"Computer Software"` instead of `"SaaS"`), the model may try to predict parameters at runtime and fail silently. Mitigation: the skill must force a programmatic fetch of the valid enum list before mapping natural-language PT-BR input to the correct EN value. Pattern: step 1 = `get_industries()`, step 2 = map PT-BR input → EN enum, step 3 = call the action.

## 4. Subagents (`.claude/agents/*.md`) — always English

Recommended by all four articles. Three reasons:

- The subagent system prompt is fixed throughout execution, so any ambiguity compounds.
- Subagents typically run on Haiku 4.5, which has the largest multilingual gap (96.1% vs 97.8% Opus/Sonnet) and drops to 73.5% strict accuracy on PT-BR in the CAPITU benchmark.
- Haiku 4.5 tool-calling reliability in PT-BR is 96.1% — over a 50-call pipeline, ~2 fail silently.

An agent with a `translator-pt` role should have its **prompt** in English ("You are a Brazilian Portuguese translator. Translate the user's text..."), even if its task is to produce PT-BR output.

## 5. Hooks — code is code, but messages matter

Architecture Level 3. Hooks are shell/Python/Node scripts triggered on PreToolUse, PostToolUse, Stop, etc. Technically the language is irrelevant for execution — `npm run lint` works in any locale.

But two attention points exist:

**Hook output returns to context.** The message a hook prints enters the model's next reasoning round. English messages align better with the rest of the system prompt and reduce friction. PT-BR works, but English is preferable.

**Hooks with `"type": "prompt"` (LLM-as-judge).** When a hook uses a Claude model (usually Haiku for cost) to evaluate a condition, PT-BR prompts have slightly lower accuracy. For critical decision logic, keep the hook prompt in English even if the output is PT-BR.

**Larger architectural principle:** non-negotiable rules go in hooks, not in CLAUDE.md or skills. The model can ignore an instruction; a hook with non-zero exit is deterministic. If you keep repeating "always run typecheck" in CLAUDE.md and the model keeps forgetting, move it to a PostToolUse hook.

## 6. Tool descriptions and MCP — critical boundary

The "Lost in Execution" paper (Jan 2026) documents that crossing the linguistic boundary between user prompt and tool interface generates "systematic failure patterns" — semantically appropriate but operationally invalid calls. None of the three tested mitigations (explicit instruction, pre-translation, post-translation) fully recover English performance.

Practical implications for skills using MCPs:

- **Tool `name` in English `snake_case`** — JSON schema technical requirement.
- **Tool `description` in English or bilingual.** PT-BR-only is the worst case. Bilingual (English description + PT-BR synonyms as triggers) is best for users writing queries in both languages.
- **Schemas with `oneOf`, nested objects, 5+ optional parameters** — where compounding error is highest — MUST have English descriptions.
- For integrations where the user mentions concepts in PT-BR but the API expects English enums, the skill must include an explicit mapping step (see Enum Guessing above).

## 7. Synthesis table — language by skill component

|Skill component|Language|Why|
|---|---|---|
|`name` (frontmatter)|English required|Spec blocks accents; training is English-dominant|
|`description` (frontmatter)|English with quoted PT-BR triggers|Level-1 routing; every word counts|
|Critical Rules / Do NOT|English|M-IFEval shows degradation on multilingual restrictions|
|Imperatives (MUST/NEVER)|English|More reliable than "DEVE/NUNCA"|
|Numbered steps with dependency|English for locks, PT-BR for descriptive prose|"Do NOT proceed until..." is better recognized|
|Technical terms (commands, APIs, enums)|English always|Canonical in training|
|Descriptive body / "When to use"|PT-BR acceptable|Loaded on demand; ~2-3pp gap|
|Hook scripts|Indifferent|Code is code|
|Hook output messages|English preferable|Returns to context, aligns with system prompt|
|Subagent prompts|English|Runs on Haiku, larger gap, persistent system prompt|
|Tool descriptions (MCP)|English or bilingual|"Lost in Execution" cross-lingual gap|

## 8. Operational practices for authoring PT-BR skills

Compiled from the articles:

- **Dual discovery test.** `mgechev/skills-best-practices` recommends 3 prompts that should activate and 3 that should not. Run all 6 in PT-BR **and** in English, measure consistency. If the skill activates in EN but not in PT-BR, adjust the description (likely missing PT-BR triggers between quotes).
- **Keep SKILL.md stable for caching.** Cache reads cost 0.1× of input. Cached static content kills 80-90% of the PT-BR linguistic tax. Do not include timestamps or volatile data in the skill body.
- **Do not switch models mid-session.** Each model has its own KV cache; switching invalidates the cached prefix, and re-warming costs more than the savings from switching.
- **Use `@file` instead of inlining.** For long PT-BR content (internal documentation, specifications), reference by path instead of copying into the skill body — the model reads only when needed.
- **Limit ~1,000 lines in CLAUDE.md** (more aggressive than the EN limit of ~1,500), due to the token tax.
- **Canonical project glossary.** For concepts with ambiguous translation ("agente autônomo", "memória persistente"), explicitly declare the EN equivalent once in CLAUDE.md or a `glossary.md` skill. Reduces semantic drift.
- **Do not force "think in Portuguese" via prompt.** Extended thinking already runs in English by default on Opus 4.6+ and Sonnet 4.6 — this is a feature, not a bug. Forcing PT-BR thinking trades quality for aesthetics.
