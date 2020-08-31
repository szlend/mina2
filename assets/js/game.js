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
    for (let [type, x, y, items] of actions) {
      switch (type) {
        case "a":
          this.setupContainer(bigInt(x), bigInt(y), items)
          break
        case "u":
          this.updateContainer(bigInt(x), bigInt(y), items)
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
        container.children[idx].texture = this.tileset[items[idx]]
      }
    }

    container.children[container.children.length - 1].text = `${partitionX}, ${partitionY}`
    container.partition = { x: partitionX, y: partitionY }
    container.visible = true
    container.cacheAsBitmap = true
  },

  updateContainer(partitionX, partitionY, items) {
    const container = this.findContainer(partitionX, partitionY)
    container.cacheAsBitmap = false

    for (let [x, y, t] of items) {
      const idx = y * this.partitionSize + x
      container.children[idx].texture = this.tileset[t]
    }

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
    container.on("pointertap", this.containerPointerTap.bind(this))
    container.on("rightclick", this.containerAltPointerTap.bind(this))

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

    const text = new PIXI.Text('TEST', { fontFamily: 'Arial', fontSize: 24, fill: 0x000000, align: 'left' })
    container.addChild(text)

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

  containerPointerTap(e) {
    const container = e.target
    const clientX = e.data.global.x
    const clientY = e.data.global.y
    const diffX = Math.abs(this.input.startClientX - clientX)
    const diffY = Math.abs(this.input.startClientY - clientY)

    if (diffX < 4 && diffY < 4) {
      const position = e.data.getLocalPosition(container)
      const offsetX = Math.floor(position.x / this.tileSize)
      const offsetY = Math.floor(position.y / this.tileSize)
      const tileX = container.partition.x.plus(bigInt(offsetX))
      const tileY = container.partition.y.plus(bigInt(offsetY))
      const endTime = (new Date()).getTime()

      if (endTime - this.input.startTime < 500) {
        this.pushEvent("reveal", { x: tileX.toString(), y: tileY.toString() })
      } else {
        this.pushEvent("flag", { x: tileX.toString(), y: tileY.toString() })
      }
    }
  },

  containerAltPointerTap(e) {
    const container = e.target
    const clientX = e.data.global.x
    const clientY = e.data.global.y
    const diffX = Math.abs(this.input.startClientX - clientX)
    const diffY = Math.abs(this.input.startClientY - clientY)

    if (diffX < 4 && diffY < 4) {
      const position = e.data.getLocalPosition(container)
      const offsetX = Math.floor(position.x / this.tileSize)
      const offsetY = Math.floor(position.y / this.tileSize)
      const tileX = container.partition.x.plus(bigInt(offsetX))
      const tileY = container.partition.y.plus(bigInt(offsetY))
      this.pushEvent("flag", { x: tileX.toString(), y: tileY.toString() })
    }
  }
}

function loadTileset(texture, tileset) {
  let result = {}
  for (let [id, [x, y]] of Object.entries(tileset)) {
    result[id] = new PIXI.Texture(texture, new PIXI.Rectangle(x, y, 128, 128))
  }
  return result
}
