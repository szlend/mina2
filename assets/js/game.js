import * as PIXI from "pixi.js"
import bigInt from "big-integer"

export default {
  mounted() {
    PIXI.Loader.shared.add("tileset", this.el.dataset.tilesetUrl)
    PIXI.Loader.shared.load((loader, resources) => {
      this.app = new PIXI.Application({ resizeTo: window, autoStart: true })
      this.canvas = this.el.appendChild(this.app.view)
      this.textureSize = Number(this.el.dataset.tileSize)
      this.tileScale = Number(this.el.dataset.tileScale)
      this.tileSize = this.textureSize * this.tileScale
      this.partitionSize = Number(this.el.dataset.partitionSize)
      this.tileset = loadTileset(resources.tileset.texture, JSON.parse(this.el.dataset.tileset), this.textureSize)

      this.bg = new PIXI.TilingSprite(this.tileset["u"])
      this.bg.scale.x = this.tileScale
      this.bg.scale.y = this.tileScale
      this.app.stage.addChild(this.bg)

      this.x = bigInt(0)
      this.y = bigInt(0)
      this.width = 0
      this.height = 0
      this.containerPool = []

      this.input = {
        updateX: bigInt(0),
        updateY: bigInt(0),
        clientX: 0,
        clientY: 0,
        startClientX: 0,
        startClientY: 0,
        startTime: 0,
        canMove: false,
      }

      this.canvas.addEventListener("mousedown", (e) => this.pointerDown(e.clientX, e.clientY))
      this.canvas.addEventListener("mouseup", () => this.pointerUp())
      this.canvas.addEventListener("mouseout", () => this.pointerUp())
      this.canvas.addEventListener("mousemove", (e) => this.pointerMoved(e.clientX, e.clientY))
      this.canvas.addEventListener("touchstart", (e) => this.pointerDown(e.touches[0].clientX, e.touches[0].clientY))
      this.canvas.addEventListener("touchend", () => this.pointerUp())
      this.canvas.addEventListener("touchmove", (e) => this.pointerMoved(e.touches[0].clientX, e.touches[0].clientY))
      this.canvas.addEventListener("contextmenu", (e) => e.preventDefault())

      this.canvas.addEventListener("wheel", (e) => {
        this.pointerDown(0, 0)
        this.pointerMoved(-e.deltaX, -e.deltaY)
        this.pointerUp()
        e.preventDefault()
      }, { passive: false })

      this.pushEvent("camera", { x: this.x.toString(), y: this.y.toString() })
      this.handleEvent("actions", ({ actions }) => this.handleActions(actions))

      this.app.ticker.add(this.tick.bind(this))
    })
  },

  disconnected() {
    // remove all children except the background
    this.app.stage.removeChildren(1)

    // clear container cache
    this.containerPool = []
  },

  reconnected() {
    this.pushEvent("camera", { x: this.x.toString(), y: this.y.toString() })
  },

  tick() {
    if (this.width !== this.app.renderer.width || this.height !== this.app.renderer.height) {
      this.width = this.app.renderer.width
      this.height = this.app.renderer.height

      // re-center the camera
      this.app.stage.pivot.x = -Math.round(this.width / 2)
      this.app.stage.pivot.y = -Math.round(this.height / 2)

      // send new screen dimensions
      this.pushEvent("resize", { width: this.width, height: this.height })
    }

    // update background position
    this.bg.x = -this.x.mod(bigInt(this.tileSize)).toJSNumber() - (Math.round(this.width / this.tileSize / 2) + 1) * this.tileSize
    this.bg.y = -this.y.mod(bigInt(this.tileSize)).toJSNumber() - (Math.round(this.height / this.tileSize / 2) + 1) * this.tileSize
    this.bg.width = (this.width + this.tileSize * 2) / this.tileScale
    this.bg.height = (this.height + this.tileSize * 2) / this.tileScale

    // update container positions
    for (let container of this.app.stage.children) {
      if (container.partition) {
        container.x = container.partition.x.times(bigInt(this.tileSize)).minus(this.x).toJSNumber()
        container.y = container.partition.y.times(bigInt(this.tileSize)).minus(this.y).toJSNumber()
      }
    }
  },

  handleActions(actions) {
    for (let [type, x, y, color, items] of actions) {
      switch (type) {
        case "a":
          this.setupContainer(bigInt(x), bigInt(y), items)
          break
        case "u":
          this.updateContainer(bigInt(x), bigInt(y), color, items)
          break
        case "r":
          this.releaseContainer(bigInt(x), bigInt(y))
          break
      }
    }
  },

  setupContainer(partitionX, partitionY, items) {
    const container = this.containerPool.pop() || this.newContainer()

    for (let y = 0; y < this.partitionSize; y++) {
      for (let x = 0; x < this.partitionSize; x++) {
        const idx = y * this.partitionSize + x
        const tile = container.children[idx]
        tile.texture = this.tileset[items[idx]]
        tile.tint = 0xFFFFFF
      }
    }

    container.partition = { x: partitionX, y: partitionY }
    container.visible = true
    container.cacheAsBitmap = true
  },

  updateContainer(partitionX, partitionY, color, items) {
    const container = this.findContainer(partitionX, partitionY)
    container.cacheAsBitmap = false

    for (let [x, y, t] of items) {
      const idx = y * this.partitionSize + x
      container.children[idx].texture = this.tileset[t]
    }

    const tint = 0xFFFFFF - color
    let alpha = 1.0

    const timer = setInterval(() => {
      container.cacheAsBitmap = false

      const fadedTint = (alpha <= 0)
        ? 0xFFFFFF
        : 0xFFFFFF - (PIXI.utils.premultiplyTint(tint, alpha) & 0xFFFFFF)

      for (let [x, y, t] of items) {
        const idx = y * this.partitionSize + x
        container.children[idx].tint = fadedTint
      }

      if (alpha <= 0) {
        clearInterval(timer)
        container.cacheAsBitmap = true
      }

      alpha -= 0.0625
    }, 16)

    container.cacheAsBitmap = true
  },

  releaseContainer(partitionX, partitionY) {
    const container = this.findContainer(partitionX, partitionY)
    container.visible = false
    container.cacheAsBitmap = false
    container.partition = null
    this.containerPool.push(container)
  },

  findContainer(partitionX, partitionY) {
    return this.app.stage.children.find(c =>
      c.visible &&
      c.partition &&
      c.partition.x.equals(partitionX) &&
      c.partition.y.equals(partitionY)
    )
  },

  newContainer() {
    const container = new PIXI.Container()

    container.buttonMode = true
    container.interactive = true
    container.on("pointerdown", this.containerPointerDown.bind(this))
    container.on("mouseup", this.containerLeftClick.bind(this))
    container.on("rightclick", this.containerRightClick.bind(this))
    container.on("tap", this.containerTouch.bind(this))

    for (let y = 0; y < this.partitionSize; y++) {
      for (let x = 0; x < this.partitionSize; x++) {
        const tile = new PIXI.Sprite(this.tileset["u"])
        tile.x = x * this.tileSize
        tile.y = y * this.tileSize
        tile.scale.x = this.tileScale
        tile.scale.y = this.tileScale
        container.addChild(tile)
      }
    }

    this.app.stage.addChild(container)
    return container
  },

  pointerDown(clientX, clientY) {
    this.input.canMove = true
    this.input.clientX = clientX
    this.input.clientY = clientY
  },

  pointerUp() {
    this.input.canMove = false
  },

  pointerMoved(clientX, clientY, force) {
    if (this.input.canMove) {
      // Update client camera position
      this.x = this.x.minus(bigInt(Math.round(clientX - this.input.clientX)))
      this.y = this.y.minus(bigInt(Math.round(clientY - this.input.clientY)))
      this.input.clientX = clientX
      this.input.clientY = clientY

      // Update server camera position
      const updateDiffX = Math.abs(this.x.minus(this.input.updateX).toJSNumber())
      const updateDiffY = Math.abs(this.y.minus(this.input.updateY).toJSNumber())

      if (updateDiffX >= this.textureSize || updateDiffY >= this.textureSize) {
        this.pushEvent("camera", { x: this.x.toString(), y: this.y.toString() })
        this.input.updateX = this.x
        this.input.updateY = this.y
      }
    }
  },

  containerPointerDown(e) {
    this.input.startClientX = e.data.global.x
    this.input.startClientY = e.data.global.y
    this.input.startTime = (new Date()).getTime()
  },

  containerLeftClick(e) {
    if (this.isWithinDeadzone(e.data.global.x, e.data.global.y)) {
      const [tileX, tileY] = this.containerEventTilePosition(e)
      this.pushEvent("reveal", { x: tileX.toString(), y: tileY.toString() })
    }
  },

  containerRightClick(e) {
    if (this.isWithinDeadzone(e.data.global.x, e.data.global.y)) {
      const [tileX, tileY] = this.containerEventTilePosition(e)
      this.pushEvent("flag", { x: tileX.toString(), y: tileY.toString() })
    }
  },

  containerTouch(e) {
    if (this.isWithinDeadzone(e.data.global.x, e.data.global.y)) {
      const [tileX, tileY] = this.containerEventTilePosition(e)
      const endTime = (new Date()).getTime()

      if (endTime - this.input.startTime < 500) {
        this.pushEvent("reveal", { x: tileX.toString(), y: tileY.toString() })
      } else {
        this.pushEvent("flag", { x: tileX.toString(), y: tileY.toString() })
      }
    }
  },

  containerEventTilePosition(event) {
    const container = event.target
    const position = event.data.getLocalPosition(container)
    const offsetX = Math.floor(position.x / this.tileSize)
    const offsetY = Math.floor(position.y / this.tileSize)
    const tileX = container.partition.x.plus(bigInt(offsetX))
    const tileY = container.partition.y.plus(bigInt(offsetY))
    return [tileX, tileY]
  },

  isWithinDeadzone(clientX, clientY) {
    const diffX = Math.abs(this.input.startClientX - clientX)
    const diffY = Math.abs(this.input.startClientY - clientY)
    return diffX < 4 && diffY < 4
  }
}

function loadTileset(texture, tileset) {
  let result = {}
  for (let [id, [x, y]] of Object.entries(tileset)) {
    result[id] = new PIXI.Texture(texture, new PIXI.Rectangle(x, y, 128, 128))
  }
  return result
}
