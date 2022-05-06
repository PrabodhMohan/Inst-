# Instrument Repository application

This application is used to create instruments.
It is possible to create an instrument in two ways.

The first is by manually adding an instrument using the "Add instrument" button and filling in the form with data about this instrument.

The second one is to import a csv file, which allows to add multiple instrument at the same time.

There is only one type of role in this application - regular user and he or she can add, edit and delete instruments.

## Core dependencies

- React 17
- Material UI 4
- Roche One kit (UI library based on Material UI)

## Specific libraries

This application uses following libraries:

- csv-string - to read file CSV and get data

## Requirements

- Node.js 14
- npm 6

## Prerequisites

### .npmrc

One needs to change the `.npmrc` file and substitute `${CI_JOB_TOKEN}` with personal GitLab Token from Roche GitLab.

> **Important**: do not commit updated version of `.npmrc` to the repository!

#### How to get token for .npmrc file:

Go to GitLab, log in with your credentials, go to "edit profile" and on the left menu click "Access Tokens". Provide your token name as you wish, add expiration date and select following scopes:

- api
- read_api
- read_repository
- write_repository
- read_registry
- write_registry

Generate the token, make sure you copy it, and paste it into the `.npmrc` file, as described in `.npmrc` section above.

### Installing dependencies

After cloning fresh repository, and changing contents of `.npmrc`, one needs to install dependencies, by running following command:

```
npm install
```

## Running application

In order to run the application, one needs to run following command:

```
npm start
```

## Testing

In order to run the tests, one needs to run following command:

```
npm run test -- --silent=false --verbose=true --watchAll
```

### Code coverage

Running tests will generate coverage report. To see the coverage, open `./coverage/lcov-report/index.html` file in browser.

## Code conventions

### File structure

The project is structured as follows:

```
src/
|- components/
|--- shared/
|----- ComponentA.jsx
|----- ComponentA.test.js
|- features/
|--- feature-a/
|----- inner-feature/
|------- InnerComponent.jsx
|------- InnerComponent.test.js
|----- redux/
|------- actions.js
|------- actionsTypes.js
|------- initialState.js
|------- reducer.js
|----- FeatureComponentA.jsx
|----- FeatureComponentA.test.js
|- gql/
|--- featureApi/
|----- mutations.js
|----- queries.js
|- icons/
|--- SvgIconA.jsx
|- reducers/index.js
|- store/configureStore.js
|- utils/
|--- utils-group/
|----- util-group-a.js
|--- util-a.js
|- views/
|--- ComponentA.jsx
|--- ComponentA.test.js
```

#### `components/` and `components/shared/`

These folders contains components that are reusable across the application, e.g. UI components (buttons), display components (lists), etc.

#### `features/`

This folder contains components grouped by the feature of the application. Components closely related to the single feature are grouped within the same folder. Feature may contain sub folders for better clarity.

If the feature uses redux, a structure is as follows:

- `actions.js` - contains all actions available in the reducer
- `actionsTypes.js` - contains all action types available in the reducer.

  An action type should be a string with following format: `[SHORT_NAME_OF_REDUCER] SHORT_NAME_OF_ACTION`

- `initialState.js` - contains initial state for the reducer
- `reducer.js` - contains reducer itself

A reducer is then passed to the root reducer, which is located in `reducers/index.js`.

If the feature uses context(s), one should create a new folder in the feature with a name of the context, e.g. `my-context` with following structure:

- `context.js` - file with context definition, typically with context definition, like so:

  ```jsx
  export const MyContext = React.createContext({});
  ```

- `MyWrapper.jsx` - file with wrapper for that context

#### `gql/`

Contains definitions of queries and mutations of the GraphQL endpoints.

#### `icons/`

Contains SVG icons wrapped as a React Components.

#### `reducers/index.js`

Root reducer

#### `store/configureStore.js`

Place where Redux store is created.

#### `utils/`

Folder where utilities functions should be placed.

#### `views/`

Folder where the views are placed.

### Writing tests

Tests are written with Jest and react-testing-library. Tests are written next to the file is tested, with a `.test.js` suffix.

> **Important**: **DO NOT CHANGE `data-testid` THAT HAS BEEN ALREADY COMMITTED**. Automation tests are relying on these values, so if the ticket does not change the requirements, these values should not be changed.
>
> The only exception is when one needs to change the component of different HTML structure in order to fix the issue, **but it should be avoided as much as it's possible!**

Every test **must** use `render` function from `src/test-utils.js`. That render function already wraps component with Mock Apollo context and Redux context.

To provide mocks for apollo, one needs to define mocks as described here: https://www.apollographql.com/docs/react/v2/development-testing/testing/#mockedprovider in the `mocksForApollo` array, in second argument of `render` function. E.g.:

```jsx
const { getByTestId } = render(<ComponentToTest />, {
  // Here mocks for apollo are defined
  mocksForApollo: [
    {
      request: {
        query: GET_DOG_QUERY,
        variables: {
          name: "Buck"
        }
      },
      result: {
        data: {
          dog: { id: "1", name: "Buck", breed: "bulldog" }
        }
      }
    }
  ]
});

expect(getByTestId("element-in-component")).toHaveTextContent("Buck");
```

> **Note**: Remember to mock all fields in the request **and** in the response, because MockedProvider of Apollo tends to fail, if not all of the fields are provided.

To provide initial state to the redux, one needs to define `initialState` object, in second argument of `render` function. E.g.:

```jsx
const { getByTestId } = render(<ComponentToTest />, {
  // Here initial state is defined
  initialState: {
    myReducer: {
      myValue: "123"
    }
  }
});

expect(getByTestId("element-in-component")).toHaveTextContent("123");
```

## Pushing the code

Each new feature or bug should be pushed to a new feature branch or bug branch - never commit to the develop branch directly.

### Feature development

If it was new feature, your feature branch should be created from the develop branch. After you've finished with your task, create a pull request to the develop branch in the GitLab. Once you merge your feature branch to the develop branch, verify that merge pipeline was successfully done.

### Deploy to internal QA environment

If you want to deploy to the internal QA environment, create a tag from develop with name `r4stest_release_x.y`, where `x.y` is next version number (typically you only want to increase `y` number).

### Deploy to test environment

If you want to deploy to the test environment, you should first merge develop branch to the test branch. Then verify that merge pipeline was successfully done. Next, create release tag from test branch with name `test_release_x.y`, where `x.y` is next version number (typically you only want to increase `y` number).

### Bugfixes

If it was a bug from your internal team of testers, create bug branch the same as feature branch from develop and make the same steps.

If it was a bug from test environment reported by roche testers, then create a bug branch from the test branch, fix the bug, and create a pull request to test branch. Then merge test branch to develop branch. When pipeline will be successfully done, create tag for internal QA environment, and if the internal testing confirms bug fix, create tag for test environment.

### Code push checks

Before pushing the code to the pull request, one needs to check:

1. If the builds passes **without warnings** (by running either `npm start` or `npm run build --cache .npm --prefer-offline`)
2. If the tests passes without fails (by running `npm run test`)

If one fails to check the above, the GitLab pipelines will fail to build and verify the change, and, in the consequence, deployment won't be possible.

## Code quality assurance

There are two sources that make sure that the code is of appropriate quality and has libraries without vulnerabilities.

SonarQube is used for code validation and WhiteSource is used for library validation.
Both should be regularly verified if the code in the project is correct in all respects.

### SonarQube

#### How to verify sonar reports:

1. First go to the website: https://partneraccess.roche.net/index.html
2. Select a region from europe (e.g. basel) and click connect
3. Enter your Roche credentials
4. A page will appear with a large button "detect receiver" and a small text "use light version" -> **CHOOSE SMALL TEXT, NOT BIG BUTTON**
5. Select the folder with the word "internet browsers"
6. Choose any Chrome there - e.g. click on "EMEA"
7. Wait until the button with the selection "enable" "not now" appears, click ENABLE
8. Then you can choose the size -> select "autosize"
9. Wait and after a while there will be a browser ->

(IF YOU HAVE NOT BEEN HERE, YOU HAVE TO TAKE THIS ADDITIONAL STEP, IF YOU ARE NOT HERE, SKIP IT)

ADDITIONAL STEP

- manually enter sonar homepage -> "sonarqube.roche.com"
  and there click projects and add it to your favorites using the star next to the link.
  Then in the input to search for projects by name, enter each of the most frequently used projects in turn, enter it and set it to "develop" at the top (not master, which is the default) and also set it as favorite. This facilitates the subsequent quick launch of reports for a given project.

In Favorites there is a link to the home page with projects and favorite projects.
For me it is, for example, a link to the logbook project.

10. select the link with projects and in the input to search for projects by name, enter the project you are interested in and check the report on develop (unless you are interested in master - then check if the master is set)

### WhiteSource

#### How to check WhiteSource:

1. First go to this link https://saas.whitesourcesoftware.com/Wss/WSS.html#!login
1. Enter login and password - your login should be your e-mail with roche and your password is the one you set when activating the account.
   (someone should add you earlier and invite you to use WhiteSource. You will receive an email to complete the account creation)
1. At the top you have a blue horizontal menu - in it, click projects
1. A list and input for searching for projects should appear - find on the list the project you are interested in (our projects are named according to the name of the application from gitlab) or enter the name of the project in input and click on the selected one.
1. The most important place that you should verify is on the right side of the dashboard with the words "Vulnerability Analysis" and "Security"
   At the bottom of these cards are statistics - they show how many libraries have vulnerabilities. 0 should appear in both places.

To get to the list of vulnerable libraries, click on "View Vulnerabilities". These libraries will be listed there, which should be taken care of - that is, their versions should be upgraded - sometimes they should be replaced with another library.

#### How to improve libraries that are vulnerable:

However, dealing with the vulnerability of libraries is not that simple and obvious.
Libraries listed there are often libraries only dependent on those that are actually used in the project. If it is a dependent library, you need to analyze if and how you can pick up a main library that uses that dependent library, but do it very carefully and check that other libraries do not need it or if the upgrade has had major changes that would break the application.

The easiest and the first way is to start the console, and type

```
npm audit
```

(this command checks all libraries in the project similarly to whitesource and lists the problematic ones in the console)

then type:

```
npm audit fix
```

(this command raises versions of libraries - but only those that have not changed by the entire version)

`npm audit` will tell you what you can pick up manually from libraries, but be careful and verify what has changed in the version and what impact it may have on other libraries.

Apart from the basic audit fix - each case should be dealt with separately and there is no one way. Here it is already necessary to analyze and make changes.

## Side notes

### Instruments data source are populated to other applications

Instruments are populated to 3 different applications into their own dedicated tables.

First application is Log Book - in this case, every time when instrument was added, edited or deleted then backend will update the dedicated table in Log Book application.

Second application is Booking - in this case, every time when instrument was added, edited or deleted then backend will update the dedicated table in Booking application. Instruments **will not** be propagated to the Booking application if the instrument is not bookable.

Third application is Instrument Status (ISV/IPSV) - in this case, every time when instrument was added, edited or deleted then backend will update the dedicated table in Instrument Status application. Instruments **will not** be propagated to the Instrument Status application if the instrument is not Visualized.

### `/info` route

`/info` route contains information about build of the frontend and backend. You will not see details of frontend build, if the build was created locally (not from CI/CD pipelines).

## Selenium report

https://digitallab.pages.roche.com/instrument-repository-fronted/
