#!/bin/bash

APP_NAME=instrumentrepository

#
# Search for proper Cloudfront distribution
#
echo -ne "Searching for cloudfront"
## search for Cloudfront specific for our application and environment
values=$(aws --region=us-east-1 resourcegroupstaggingapi get-resources \
    --tag-filters "Key=SoftGroupName,Values=glodigitallab" "Key=Application,Values=${APP_NAME}" "Key=Environment,Values=${AWS_ENV}" "Key=Region,Values=${DEFAULT_REGION}" \
    --resource-type-filters 'cloudfront' \
    | jq -r ".ResourceTagMappingList[].ResourceARN" | sed 's:.*/::' \
    | xargs -I {} aws --region=${DEFAULT_REGION} cloudfront get-distribution --id {} \
    | jq -r '.Distribution.Id, .Distribution.DomainName')

## export data to environment variables
ITER=0
for val in ${values}
    do
    keys=("distribution_id" "domain_name")
	KEY=${keys[$ITER]}
	if [ "${KEY}" != "" ]; then
	    export ${KEY}="${val}"
	fi
	ITER=$(expr $ITER + 1)
done

frontend_bucket_name=$(
aws --region=${DEFAULT_REGION} cloudfront get-distribution-config --id ${distribution_id} \
  | jq -r '.DistributionConfig.Origins.Items[] | select(.Id | test(".frontend")).DomainName' \
  | awk -F'.s3' '{print $1}'
  )

if [ "x${distribution_id}" != "x" ] && [ "x${domain_name}" != "x" ] && [ "x${frontend_bucket_name}" != "x" ]; then
    echo -e "\t\t\t OK"
else
    echo -e "\t\t\t NOK"
    exit 1
fi

#
# Search for proper cognito user pool
#

echo -ne "Searching for cognito"
valuesCognito=$(
aws --region=${DEFAULT_REGION} cognito-idp list-user-pools --max-results 20 | jq -r '.UserPools[].Id' \
  | xargs -I {} aws --region=${DEFAULT_REGION} cognito-idp describe-user-pool --user-pool-id {} \
  | jq -r "select(.UserPool.UserPoolTags.Application==\"cognito\" and .UserPool.UserPoolTags.Environment==\"${AWS_ENV}\")  | .UserPool.Id, .UserPool.Name, .UserPool.Domain, .UserPool.Arn"
)

ITER=0
for val in ${valuesCognito}
    do
    keys=("user_pool_id" "user_pool_name" "user_pool_domain" "user_pool_arn")
	KEY=${keys[$ITER]}
	if [ "${KEY}" != "" ]; then
	    export ${KEY}="${val}"
	fi
	ITER=$(expr $ITER + 1)
done

export user_pool_region=$(echo ${user_pool_arn}|cut -d ":" -f4)

if [ "x${user_pool_id}" != "x" ] && [ "x${user_pool_name}" != "x" ] && [ "x${user_pool_domain}" != "x" ] && [ "x${user_pool_arn}" != "x" ]; then
    echo -e "\t\t\t\t OK"
else
    echo -e "\t\t\t\t NOK"
    exit 1
fi

#
# Search for proper cognito user pool client
#
echo -ne "Searching for cognito user pool client"
values=$(
aws --region=${DEFAULT_REGION} cognito-idp list-user-pool-clients --user-pool-id ${user_pool_id} \
    | jq -r ".UserPoolClients[0]" \
    | jq -r ".ClientId, .ClientName")

ITER=0
for val in ${values}
    do
    keys=("user_pool_client_id" "user_pool_client_name")
	KEY=${keys[$ITER]}
	if [ "${KEY}" != "" ]; then
	    export ${KEY}="${val}"
	fi
	ITER=$(expr $ITER + 1)
done

if [ "x${user_pool_client_id}" != "x" ] && [ "x${user_pool_client_name}" != "x" ]; then
    echo -e "\t\t OK"
else
    echo -e "\t\t NOK"
    exit 1
fi
#
# Search for proper cognito identity pool
#
echo -ne "Searching for cognito identity pool"
export cognito_identity_pool_id=$(aws --region=${DEFAULT_REGION} cognito-identity list-identity-pools --max-results 60 | jq -r ".IdentityPools[] | select(.IdentityPoolName==\"glodigitallab_identity_pool_${AWS_ENV}\") | .IdentityPoolId")

if [ "x${cognito_identity_pool_id}" != "x" ]; then
    echo -e "\t\t OK"
else
    echo -e "\t\t NOK"
    exit 1
fi

#
# Search for proper appsync
#
echo -ne "Searching for appsync"
values=$(aws --region=${DEFAULT_REGION} appsync list-graphql-apis | jq -r ".graphqlApis[] | select(.tags.Environment==\"${AWS_ENV}\" and .tags.Application==\"${APP_NAME}\" and .tags.SoftGroupName==\"glodigitallab\") | .uris[]")
ITER=0
for val in ${values}
    do
    keys=("appsync_realtime_graphql_api" "appsync_graphql_api")
	KEY=${keys[$ITER]}
	if [ "${KEY}" != "" ]; then
	    export ${KEY}="${val}"
	fi
	ITER=$(expr $ITER + 1)
done

if [ "x${appsync_graphql_api}" != "x" ]; then
    echo -e "\t\t\t\t OK"
else
    echo -e "\t\t\t\t NOK"
    exit 1
fi

updatedAt=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

if [ "$CI_JOB_ID" == "" ]; then
  pipelineId="0.0.0"
else
  pipelineId=$CI_JOB_ID
fi

deployment_version=$(echo ${CI_COMMIT_REF_NAME} | cut -d "_" -f3 | sed 's/[^0-9\.]//g')
if [ "$deployment_version" == "" ]; then
  deployment_version=$pipelineId
fi

echo "---------------- AWS environment elements used for this deployment ---------------------------------------"
echo "AWS region: ${DEFAULT_REGION}"
echo "Cognito identity pool Id: ${cognito_identity_pool_id}"
echo "Cognito user pool Id: ${user_pool_id}"
echo "Cognito user pool client Id: ${user_pool_client_id}"
echo "Cognito user pool domain: ${user_pool_domain}"
echo "AppSync graphql API: ${appsync_graphql_api}"
echo "Cloudfront distribution Id: ${distribution_id}"
echo "Cloudfront domain name: ${domain_name}"

echo "Module name: ${APP_NAME}-frontend"
echo "Module version: ${deployment_version}"
echo "Module hash: ${CI_COMMIT_SHORT_SHA}"
echo "Updated at: ${updatedAt}"

echo "Cognito login enabled: ${COGNITO_LOGIN_ENABLED}"
echo "Cognito provider id: ${COGNITO_PROVIDER_ID}"
## create React .env file
cat << EOF > .env
#common
REACT_APP_AWS_PROJECT_REGION=${DEFAULT_REGION}
REACT_APP_AWS_COGNITO_REGION=${user_pool_region}
REACT_APP_AWS_APPSYNC_REGION=${DEFAULT_REGION}

REACT_APP_COGNITO_LOGIN_ENABLED=${COGNITO_LOGIN_ENABLED}
REACT_APP_COGNITO_PROVIDER_ID=${COGNITO_PROVIDER_ID}

REACT_APP_AWS_COGNITO_IDENTITY_POOL_ID=${cognito_identity_pool_id}
REACT_APP_AWS_USER_POOLS_ID=${user_pool_id}
REACT_APP_AWS_USER_POOLS_WEB_CLIENT_ID=${user_pool_client_id}
REACT_APP_OAUTH_DOMAIN=${user_pool_domain}.auth.${user_pool_region}.amazoncognito.com

REACT_APP_AWS_GRAPHQL_ENDPOINT=${appsync_graphql_api}
REACT_APP_GRAPHQL_ENDPOINT_HEALTH_CHECK=${appsync_graphql_api}
REACT_APP_GRAPHQL_ENDPOINT_CLOUDFRONT=https://${domain_name}/

REACT_APP_MODULE_NAME=${APP_NAME}-frontend
REACT_APP_MODULE_VERSION=${deployment_version}
REACT_APP_CI_JOB_ID=${CI_JOB_ID}
REACT_APP_COMMIT_HASH=${CI_COMMIT_SHORT_SHA}
REACT_APP_UPDATED_AT=${updatedAt}
EOF
