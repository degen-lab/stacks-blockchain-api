/* tslint:disable */
/* eslint-disable */
/**
 * Stacks 2.0 Blockchain API
 * This is the documentation for the Stacks 2.0 Blockchain API.  It is comprised of two parts; the Stacks Blockchain API and the Stacks Core API.  [![Run in Postman](https://run.pstmn.io/button.svg)](https://app.getpostman.com/run-collection/614feab5c108d292bffa#?env%5BStacks%20Blockchain%20API%5D=W3sia2V5Ijoic3R4X2FkZHJlc3MiLCJ2YWx1ZSI6IlNUMlRKUkhESE1ZQlE0MTdIRkIwQkRYNDMwVFFBNVBYUlg2NDk1RzFWIiwiZW5hYmxlZCI6dHJ1ZX0seyJrZXkiOiJibG9ja19pZCIsInZhbHVlIjoiMHgiLCJlbmFibGVkIjp0cnVlfSx7ImtleSI6Im9mZnNldCIsInZhbHVlIjoiMCIsImVuYWJsZWQiOnRydWV9LHsia2V5IjoibGltaXRfdHgiLCJ2YWx1ZSI6IjIwMCIsImVuYWJsZWQiOnRydWV9LHsia2V5IjoibGltaXRfYmxvY2siLCJ2YWx1ZSI6IjMwIiwiZW5hYmxlZCI6dHJ1ZX0seyJrZXkiOiJ0eF9pZCIsInZhbHVlIjoiMHg1NDA5MGMxNmE3MDJiNzUzYjQzMTE0ZTg4NGJjMTlhODBhNzk2MzhmZDQ0OWE0MGY4MDY4Y2RmMDAzY2RlNmUwIiwiZW5hYmxlZCI6dHJ1ZX0seyJrZXkiOiJjb250cmFjdF9pZCIsInZhbHVlIjoiU1RKVFhFSlBKUFBWRE5BOUIwNTJOU1JSQkdRQ0ZOS1ZTMTc4VkdIMS5oZWxsb193b3JsZFxuIiwiZW5hYmxlZCI6dHJ1ZX0seyJrZXkiOiJidGNfYWRkcmVzcyIsInZhbHVlIjoiYWJjIiwiZW5hYmxlZCI6dHJ1ZX0seyJrZXkiOiJjb250cmFjdF9hZGRyZXNzIiwidmFsdWUiOiJTVEpUWEVKUEpQUFZETkE5QjA1Mk5TUlJCR1FDRk5LVlMxNzhWR0gxIiwiZW5hYmxlZCI6dHJ1ZX0seyJrZXkiOiJjb250cmFjdF9uYW1lIiwidmFsdWUiOiJoZWxsb193b3JsZCIsImVuYWJsZWQiOnRydWV9LHsia2V5IjoiY29udHJhY3RfbWFwIiwidmFsdWUiOiJzdG9yZSIsImVuYWJsZWQiOnRydWV9LHsia2V5IjoiY29udHJhY3RfbWV0aG9kIiwidmFsdWUiOiJnZXQtdmFsdWUiLCJlbmFibGVkIjp0cnVlfV0=) 
 *
 * The version of the OpenAPI document: 1.0.0
 * 
 *
 * NOTE: This class is auto generated by OpenAPI Generator (https://openapi-generator.tech).
 * https://openapi-generator.tech
 * Do not edit the class manually.
 */


import * as runtime from '../runtime';
import {
    RunFaucetResponse,
    RunFaucetResponseFromJSON,
    RunFaucetResponseToJSON,
} from '../models';

export interface RunFaucetBtcRequest {
    address: string;
}

export interface RunFaucetStxRequest {
    address: string;
    stacking?: boolean;
}

/**
 * FaucetsApi - interface
 * 
 * @export
 * @interface FaucetsApiInterface
 */
export interface FaucetsApiInterface {
    /**
     * Get BTC tokens for the testnet
     * @summary Get BTC tokens
     * @param {string} address BTC address
     * @param {*} [options] Override http request option.
     * @throws {RequiredError}
     * @memberof FaucetsApiInterface
     */
    runFaucetBtcRaw(requestParameters: RunFaucetBtcRequest): Promise<runtime.ApiResponse<RunFaucetResponse>>;

    /**
     * Get BTC tokens for the testnet
     * Get BTC tokens
     */
    runFaucetBtc(requestParameters: RunFaucetBtcRequest): Promise<RunFaucetResponse>;

    /**
     * Get STX tokens for the testnet
     * @summary Get STX tokens
     * @param {string} address STX address
     * @param {boolean} [stacking] Request the amount of STX needed for stacking
     * @param {*} [options] Override http request option.
     * @throws {RequiredError}
     * @memberof FaucetsApiInterface
     */
    runFaucetStxRaw(requestParameters: RunFaucetStxRequest): Promise<runtime.ApiResponse<RunFaucetResponse>>;

    /**
     * Get STX tokens for the testnet
     * Get STX tokens
     */
    runFaucetStx(requestParameters: RunFaucetStxRequest): Promise<RunFaucetResponse>;

}

/**
 * 
 */
export class FaucetsApi extends runtime.BaseAPI implements FaucetsApiInterface {

    /**
     * Get BTC tokens for the testnet
     * Get BTC tokens
     */
    async runFaucetBtcRaw(requestParameters: RunFaucetBtcRequest): Promise<runtime.ApiResponse<RunFaucetResponse>> {
        if (requestParameters.address === null || requestParameters.address === undefined) {
            throw new runtime.RequiredError('address','Required parameter requestParameters.address was null or undefined when calling runFaucetBtc.');
        }

        const queryParameters: runtime.HTTPQuery = {};

        if (requestParameters.address !== undefined) {
            queryParameters['address'] = requestParameters.address;
        }

        const headerParameters: runtime.HTTPHeaders = {};

        const response = await this.request({
            path: `/extended/v1/faucets/btc`,
            method: 'POST',
            headers: headerParameters,
            query: queryParameters,
        });

        return new runtime.JSONApiResponse(response, (jsonValue) => RunFaucetResponseFromJSON(jsonValue));
    }

    /**
     * Get BTC tokens for the testnet
     * Get BTC tokens
     */
    async runFaucetBtc(requestParameters: RunFaucetBtcRequest): Promise<RunFaucetResponse> {
        const response = await this.runFaucetBtcRaw(requestParameters);
        return await response.value();
    }

    /**
     * Get STX tokens for the testnet
     * Get STX tokens
     */
    async runFaucetStxRaw(requestParameters: RunFaucetStxRequest): Promise<runtime.ApiResponse<RunFaucetResponse>> {
        if (requestParameters.address === null || requestParameters.address === undefined) {
            throw new runtime.RequiredError('address','Required parameter requestParameters.address was null or undefined when calling runFaucetStx.');
        }

        const queryParameters: runtime.HTTPQuery = {};

        if (requestParameters.address !== undefined) {
            queryParameters['address'] = requestParameters.address;
        }

        if (requestParameters.stacking !== undefined) {
            queryParameters['stacking'] = requestParameters.stacking;
        }

        const headerParameters: runtime.HTTPHeaders = {};

        const response = await this.request({
            path: `/extended/v1/faucets/stx`,
            method: 'POST',
            headers: headerParameters,
            query: queryParameters,
        });

        return new runtime.JSONApiResponse(response, (jsonValue) => RunFaucetResponseFromJSON(jsonValue));
    }

    /**
     * Get STX tokens for the testnet
     * Get STX tokens
     */
    async runFaucetStx(requestParameters: RunFaucetStxRequest): Promise<RunFaucetResponse> {
        const response = await this.runFaucetStxRaw(requestParameters);
        return await response.value();
    }

}