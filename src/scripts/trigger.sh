#!/bin/bash

PARAM_PROJECT_SLUG="$(circleci env subst "$PARAM_PROJECT_SLUG")"
PARAM_TOKEN="$(circleci env subst "$PARAM_TOKEN")"
PARAM_BRANCH="$(circleci env subst "$PARAM_BRANCH")"
PARAM_TAG="$(circleci env subst "$PARAM_TAG")"
PARAM_DEFINITION_ID="$(circleci env subst "$PARAM_DEFINITION_ID")"

if ! command -v jq >/dev/null 2>&1; then
    echo "JQ is required"
    exit 1
fi

if [ -n "$PARAM_PROJECT_SLUG" ]; then
    echo "A project slug is required"
    exit 1
fi

if [ -n "$PARAM_DEFINITION_ID" ]; then
    echo "A definition id is required"
    exit 1
fi

if [ -n "$PARAM_TOKEN" ]; then
    echo "A token is required"
    exit 1
fi

if [ -n "$PARAM_BRANCH" ]; then
    echo "Triggering from branch $PARAM_BRANCH"
    DATA=$(jq -n --arg definition_id "$PARAM_DEFINITION_ID" --arg branch "$PARAM_BRANCH" \
        '{definition_id: $definition_id, config: {branch: $branch}, checkout: {branch: $branch}}')
elif [ -n "$PARAM_TAG" ]; then
    echo "Triggering from tag $PARAM_TAG"
    DATA=$(jq -n --arg definition_id "$PARAM_DEFINITION_ID" --arg tag "$PARAM_TAG" \
        '{definition_id: $definition_id, config: {tag: $tag}, checkout: {tag: $tag}}')
else
    echo "A branch or a tag is required"
    exit 1
fi

curl -X POST "https://circleci.com/api/v2/project/$PARAM_PROJECT_SLUG/pipeline/run" \
  --header "Circle-Token: $PARAM_TOKEN" \
  --header "content-type: application/json" \
  --data "$DATA"