import tl = require('azure-pipelines-task-lib/task');
import ado = require('azure-devops-node-api');
import { ITaskAgentApi } from 'azure-devops-node-api/TaskAgentApi';
import { VariableGroup, VariableValue, VariableGroupParameters } from 'azure-devops-node-api/interfaces/TaskAgentInterfaces';

function doIncrement(initialValue: string | undefined, maxPatch: string | undefined, maxMinor: string | undefined): string {
    let fixed : string = !initialValue ? '0.0.0' : initialValue;
    const splitValue = fixed.split('.');

    const fixedMaxPatch = maxPatch ? Number.parseInt(maxPatch, 10) : Infinity;
    const fixedMaxMinor = maxMinor ? Number.parseInt(maxMinor, 10) : Infinity;

    const major: number = splitValue.length >= 1 ? Number.parseInt(splitValue[0], 10) : 0;
    const minor: number = splitValue.length >= 2 ? Number.parseInt(splitValue[1], 10) : 0;
    const patch: number = splitValue.length >= 3 ? Number.parseInt(splitValue[2], 10) : 0;

    console.log("Original:");
    console.log("Major: ", major);
    console.log("Minor: ", minor);
    console.log("Patch: ", patch);

    let newMajor = major;
    let newMinor = minor;
    let newPatch = patch + 1;

    if (newPatch > fixedMaxPatch) {
        newPatch = 0;
        newMinor += 1;
    }

    if (newMinor > fixedMaxMinor) {
        newMinor = 0;
        newMajor += 1;
    }

    console.log("Updated:");
    console.log("Major: ", major);
    console.log("Minor: ", minor);
    console.log("Patch: ", patch);

    return `${newMajor}.${newMinor}.${newPatch}`;
}

async function run() {
    try {
        const variableGroupName: string | undefined = tl.getInput('variablegroupname', true);
        const variableName: string | undefined = tl.getInput('variablename', true);
        const maxPatch: string | undefined = tl.getInput('maxpatch', false);
        const maxMinor: string | undefined = tl.getInput('maxminor', false);
        
        const tfsCollectionURI: string | undefined = tl.getVariable('system.teamfoundationcollectionuri');
        const project: string | undefined = tl.getVariable('system.teamproject');

        if (!project || !tfsCollectionURI) {
            throw new Error(`Could not get either the project (${project}) or the uri (${tfsCollectionURI}). :(`);
        }

        console.log("Group Name: ", variableGroupName);
        console.log("Variable Name: ", variableName);
        console.log("Max Patch: ", maxPatch);
        console.log("Max Minor: ", maxMinor);
        console.log("TFS Collection URI: ", tfsCollectionURI);

        console.log("");
        console.log("Getting Access Token...");
        const accessToken: string | undefined = tl.getEndpointAuthorizationParameter('SYSTEMVSSCONNECTION', 'ACCESSTOKEN', false);
        if (!accessToken)
        {
            throw new Error("Could not get access token :(");
        }

        let authHandler = ado.getHandlerFromToken(accessToken);
        let connection = new ado.WebApi(tfsCollectionURI, authHandler);
        let taskAgentApi: ITaskAgentApi = await connection.getTaskAgentApi();

        console.log(`Querying for Variable Group '${variableGroupName}'`);
        const groups: VariableGroup[] = await taskAgentApi.getVariableGroups(project as string, variableGroupName);
        
        if (groups.length === 0) throw new Error(`Could not find variable group with name '${variableGroupName}' :(`);
        if (groups.length > 1) throw new Error(`Found more than one variable group with the name '${variableGroupName}' :(`);

        const group = groups[0];
        console.log(`Found Variable Group ${group.name} (${group.id})`);

        if(!group.variables) throw new Error('This variable group does not have any variables. :(');

        let varValue: VariableValue = group.variables[variableName as string];
        console.log(`Current Version Number: ${varValue.value}`);

        varValue.value = doIncrement(varValue.value, maxPatch, maxMinor);
        
        console.log('Updating Version Number...');
        const variableGroupParameters: VariableGroupParameters = {
            variables: {
                variableName: varValue
            }
        };
        const updatedGroup = await taskAgentApi.updateVariableGroup(variableGroupParameters, group.id as number);
        console.log(`Updated variable group ${updatedGroup.name} (${updatedGroup.id})!!!`);

        tl.setResult(tl.TaskResult.Succeeded, 'Finished :)');
    }
    catch (err: any)
    {
        tl.setResult(tl.TaskResult.Failed, err.message);
    }
}

run();
