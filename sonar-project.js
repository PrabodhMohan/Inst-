const sonarqubeScanner = require("sonarqube-scanner");
sonarqubeScanner(
  {
    options: {
      "sonar.projectName": "Roche.RMD.DigitalLab.InstrumentRepository",
      "sonar.projectKey": "Roche.RMD.DigitalLab.InstrumentRepository",
      "sonar.sources": "./src",
      "sonar.test.inclusions": "**/*.test.js",
      "sonar.javascript.lcov.reportPaths": "coverage/lcov.info",
      "sonar.javascript.file.suffixes": ".js,.jsx",
      "sonar.coverage.exclusions":
        "**/*.test.js, **/*.test.jsx, **/utils/test/*, **/icons/*, **/__mocks__/**,**/setupTests.js,**/reportWebVitals.js, **/appSyncClient.js, **/test-utils.js,**/test/data-test.js",
      "sonar.exclusions": "**/utils/test/*, **/icons/*, **/__mocks__/**"
    },
  },
  () => {}
);
