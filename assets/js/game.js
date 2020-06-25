import * as PIXI from "pixi.js"

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

      this.x = BigInt(0)
      this.y = BigInt(0)
      this.lastX = BigInt(0)
      this.lastY = BigInt(0)
      this.moving = false
      this.moved = false
      this.touchX = 0
      this.touchY = 0
      this.actions = []
      this.containerPool = []

      this.canvas.addEventListener("mousedown", () => this.moving = true)
      this.canvas.addEventListener("mouseup", () => this.moving = this.moved = false)
      this.canvas.addEventListener("mouseout", () => this.moving = this.moved = false)

      this.canvas.addEventListener("mousemove", (e) => {
        if (this.moving) {
          this.moved = true
          this.x -= BigInt(Math.round(e.movementX))
          this.y -= BigInt(Math.round(e.movementY))
        }
      })

      this.canvas.addEventListener("touchstart", (e) => {
        this.clientX = e.touches[0].clientX
        this.clientY = e.touches[0].clientY
      })

      this.canvas.addEventListener("touchmove", (e) => {
        this.x -= BigInt(Math.round(e.touches[0].clientX - this.touchX))
        this.y -= BigInt(Math.round(e.touches[0].clientY - this.touchY))
        this.touchX = e.touches[0].clientX
        this.touchY = e.touches[0].clientY
      })

      this.canvas.addEventListener("wheel", (e) => {
        this.x += BigInt(Math.round(e.deltaX))
        this.y += BigInt(Math.round(e.deltaY))
        e.preventDefault();
      }, { passive: false })

      this.pushEvent("resize", { width: this.app.renderer.width, height: this.app.renderer.height })
      this.pushEvent("camera", { x: this.x.toString(), y: this.y.toString() })

      this.app.ticker.add(this.tick.bind(this))
    })
  },

  updated() {
    this.actions.push.apply(this.actions, JSON.parse(this.el.dataset.actions))
  },

  tick() {
    // handle any received actions
    this.handleActions()

    // send camera updates
    if (Math.abs(Number(this.x - this.lastX)) >= this.tileSize * 4 || Math.abs(Number(this.y - this.lastY)) >= 128) {
      this.pushEvent("camera", { x: this.x.toString(), y: this.y.toString() })
      this.lastX = this.x
      this.lastY = this.y
    }

    // re-center the camera
    this.app.stage.pivot.x = -Math.round(this.app.renderer.width / 2)
    this.app.stage.pivot.y = -Math.round(this.app.renderer.height / 2)

    // update background position
    this.bg.x = -Number(this.x % BigInt(this.tileSize)) - (Math.round(this.app.renderer.width / this.tileSize / 2) + 1) * this.tileSize
    this.bg.y = -Number(this.y % BigInt(this.tileSize)) - (Math.round(this.app.renderer.height / this.tileSize / 2) + 1) * this.tileSize
    this.bg.width = (this.app.renderer.width + this.tileSize * 2) / this.tileScale
    this.bg.height = (this.app.renderer.height + this.tileSize * 2) / this.tileScale

    // update container positions
    for (let container of this.app.stage.children) {
      if (container.partition) {
        container.x = Number(container.partition.x * BigInt(this.tileSize) - this.x)
        container.y = Number(container.partition.y * BigInt(this.tileSize) - this.y)
      }
    }
  },

  handleActions() {
    for (let [type, x, y, items] of this.actions) {
      switch (type) {
        case "a":
          this.addContainer(BigInt(x), BigInt(y), items)
          break
        case "r":
          this.removeContainer(BigInt(x), BigInt(y))
          break
      }
    }

    this.actions.length = 0
  },

  addContainer(partitionX, partitionY, items) {
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

  removeContainer(partitionX, partitionY) {
    const container = this.app.stage.children.find(c =>
      c.visible &&
      c.partition &&
      c.partition.x === partitionX &&
      c.partition.y === partitionY
    )
    container.visible = false
    container.cacheAsBitmap = false
    container.partition = null
    this.containerPool.push(container)
  },

  newContainer() {
    const container = new PIXI.Container()

    container.buttonMode = true
    container.interactive = true
    container.on("pointerup", (e) => {
      if (!this.moved) {
        const position = e.data.getLocalPosition(container)
        const offsetX = Math.floor(position.x / this.tileSize)
        const offsetY = Math.floor(position.y / this.tileSize)
        console.log(container.partition.x + BigInt(offsetX), container.partition.y + BigInt(offsetY))
      }
    })

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
}

function loadTileset(texture, tileset) {
  let result = {}
  for (let [id, [x, y]] of Object.entries(tileset)) {
    result[id] = new PIXI.Texture(texture, new PIXI.Rectangle(x, y, 128, 128))
  }
  return result
}
