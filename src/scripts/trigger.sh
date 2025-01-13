#!/bin/bash

PARAM_PROJECT_SLUG="$(circleci env subst "$PARAM_PROJECT_SLUG")"
PARAM_TOKEN="$(circleci env subst "$PARAM_TOKEN")"
PARAM_BRANCH="$(circleci env subst "$PARAM_BRANCH")"
PARAM_TAG="$(circleci env subst "$PARAM_TAG")"
PARAM_DEFINITION_ID="$(circleci env subst "$PARAM_DEFINITION_ID")"
PARAM_PARAMETERS="$(circleci env subst "$PARAM_PARAMETERS")"

if ! command -v jq >/dev/null 2>&1; then
    echo "JQ is required"
    exit 1
fi

if [ -z "$PARAM_PROJECT_SLUG" ]; then
    echo "A project slug is required"
    exit 1
fi

if [ -z "$PARAM_DEFINITION_ID" ]; then
    echo "A definition id is required"
    exit 1
fi

if [ -z "$PARAM_TOKEN" ]; then
    echo "A token is required"
    exit 1
fi

if [ -n "$PARAM_PARAMETERS" ]; then
    PARAMETERS=$(echo "$PARAM_PARAMETERS" | awk -F, '{
        for (i = 1; i <= NF; i++) {
            split($i, pair, "=");
            if (i > 1) printf ",";
            printf "\""pair[1]"\":\""pair[2]"\"";
        }
    }' | sed 's/^/{/; s/$/}/')
else
    PARAMETERS="{}"
fi

if [ -n "$PARAM_BRANCH" ]; then
    echo "Triggering from branch $PARAM_BRANCH"
    echo "With parameters $PARAMETERS"
    DATA=$(jq -n --arg definition_id "$PARAM_DEFINITION_ID" --arg branch "$PARAM_BRANCH" --argjson params "$PARAMETERS" \
        '{definition_id: $definition_id, config: {branch: $branch}, checkout: {branch: $branch}, parameters: $params}')
elif [ -n "$PARAM_TAG" ]; then
    echo "Triggering from tag $PARAM_TAG"
    echo "With parameters $PARAMETERS"
    DATA=$(jq -n --arg definition_id "$PARAM_DEFINITION_ID" --arg tag "$PARAM_TAG" --argjson "$PARAMETERS" \
        '{definition_id: $definition_id, config: {tag: $tag}, checkout: {tag: $tag}, parameters: $params}')
else
    echo "A branch or a tag is required"
    exit 1
fi

curl -X POST "https://circleci.com/api/v2/project/$PARAM_PROJECT_SLUG/pipeline/run" \
  --header "Circle-Token: $PARAM_TOKEN" \
  --header "content-type: application/json" \
  --data "$DATA"