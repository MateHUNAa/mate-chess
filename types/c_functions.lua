-- DOC GENERATED WITH ChatGPT <3

---@meta
-- c_functions.lua — Type definitions for Functions table

-------------------------------------------------
-- Utility Types
-------------------------------------------------
---@diagnostic disable: duplicate-doc-field

---@class vector3
---@field x number
---@field y number
---@field z number

---@class vector4: vector3
---@field w number

---@class makePedData
---@field coords vector4
---@field freeze boolean
---@field collision boolean
---@field scenario string
---@field anim table

-------------------------------------------------
-- Main Functions Table
-------------------------------------------------

---@class Functions
---@field TeleportPlayer fun(pos: vector3|vector4, handleCam?: boolean)
---@field FindPlayerPointInRadius fun(r: number, centerCoord: vector3): vector3
---@field FindPointInRadius fun(r: number, centerCoord: vector3): vector3
---@field loadModel fun(model: string)
---@field unloadModel fun(model: string)
---@field loadAnimDict fun(dict: string)
---@field unloadAnimDict fun(dict: string)
---@field loadPtfxDict fun(dict: string)
---@field unloadPtfxDict fun(dict: string)
---@field makeProp fun(data: { prop: string, coords: vector4 }, freeze: boolean, synced: boolean): number
---@field makeBlip fun(data: { coords: vector3, name: string, sprite: number, col: number, scale?: number, disp?: number, category?: number }): number
---@field makePed fun(model: string, data: makePedData, options?: table)
---@field destoryProp fun(entity: number)
---@field loadDrillSound fun()
---@field unloadDrillSound fun()
---@field lookAtMe fun(entity: number)
---@field lookEnt fun(entity: number|vector3)
---@field lockInv fun(toggle: boolean)
---@field progressBar fun(data: { time: number, label: string, dead?: boolean, cancel?: boolean, dict?: string, anim?: string, flag?: number, task?: string }): boolean
---@field toggleItem fun(give: number|boolean, item: string, amount: number)
---@field HasItem fun(items: string, amount: number): boolean
---@field pairsByKeys fun(t: table): fun(): string, any
---@field CapitalizeFirstLetter fun(word: string): string
---@field MoveTo fun(destination: vector3|number): boolean
---@field RotToDir fun(rotation: vector3): vector3
---@field GetVehicleProps fun(model: string): table

Functions = {}

---@param inputStr string
---@return string
Functions.CapitalizeFirstLetter = function(inputStr) end
