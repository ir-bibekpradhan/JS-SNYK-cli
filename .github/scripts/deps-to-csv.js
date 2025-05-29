const fs = require('fs');

function flattenDependencies(deps, parent = '', list = []) {
  for (const [name, info] of Object.entries(deps || {})) {
    const fullName = parent ? `${parent} > ${name}` : name;
    list.push({
      name,
      version: info.version,
      path: fullName,
    });
    flattenDependencies(info.dependencies, fullName, list);
  }
  return list;
}

const json = JSON.parse(fs.readFileSync('dependencies.json'));
const deps = flattenDependencies(json.dependencies);

const csvLines = ['name,version,path'];
for (const dep of deps) {
  csvLines.push(`${dep.name},${dep.version},"${dep.path}"`);
}

fs.writeFileSync('dependencies.csv', csvLines.join('\n'));
console.log('CSV written to dependencies.csv');
