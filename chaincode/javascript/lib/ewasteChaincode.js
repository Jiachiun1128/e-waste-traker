'use strict';

const { Contract } = require('fabric-contract-api');

class EwasteChaincode extends Contract {

    async InitLedger(ctx) {
        console.info('Initializing ledger');
        // Optional: you can add sample records here with putState()
        return JSON.stringify({ message: 'Ledger initialized' });
    }

    async DeviceExists(ctx, deviceId) {
        const data = await ctx.stub.getState(deviceId);
        return data && data.length > 0;
    }

    async CreateDevice(ctx, deviceId, category, brand, model, weight, condition, location) {
        if (await this.DeviceExists(ctx, deviceId)) {
            throw new Error(`Device ${deviceId} already exists`);
        }

        const weightNum = Number(weight);
        if (!Number.isFinite(weightNum) || weightNum <= 0) {
            throw new Error(`Invalid weight: ${weight}`);
        }

        const owner = ctx.clientIdentity.getMSPID(); // org-level owner (OK if intended)

        const device = {
            deviceId,
            category,
            brand,
            model,
            weight: weightNum,
            condition,
            currentOwner: owner,
            location,
            status: 'REGISTERED',
            createdAt: new Date().toISOString()
        };

        await ctx.stub.putState(deviceId, Buffer.from(JSON.stringify(device)));
        return JSON.stringify(device);
    }

    async QueryDevice(ctx, deviceId) {
        const deviceJSON = await ctx.stub.getState(deviceId);
        if (!deviceJSON || deviceJSON.length === 0) {
            throw new Error(`Device ${deviceId} does not exist`);
        }
        return deviceJSON.toString();
    }

    async GetAllDevices(ctx) {
        const allResults = [];
        const iterator = await ctx.stub.getStateByRange('', '');

        try {
            while (true) {
                const result = await iterator.next();
                if (result.done) break;

                const strValue = result.value.value.toString('utf8');
                try {
                    allResults.push(JSON.parse(strValue));
                } catch (err) {
                    // if some keys aren't JSON, still record raw value
                    allResults.push({ key: result.value.key, value: strValue });
                }
            }
        } finally {
            await iterator.close();
        }

        return JSON.stringify(allResults);
    }

    async TransferDevice(ctx, deviceId, newOwner) {
        const deviceJSON = await this.QueryDevice(ctx, deviceId);
        const device = JSON.parse(deviceJSON);

        // Basic access control: only current owner org can transfer
        const callerOrg = ctx.clientIdentity.getMSPID();
        if (device.currentOwner !== callerOrg) {
            throw new Error(`Only current owner (${device.currentOwner}) can transfer this device`);
        }

        device.currentOwner = newOwner;
        device.status = 'TRANSFERRED';
        device.transferredAt = new Date().toISOString();

        await ctx.stub.putState(deviceId, Buffer.from(JSON.stringify(device)));
        return JSON.stringify(device);
    }
}

module.exports = EwasteChaincode;

