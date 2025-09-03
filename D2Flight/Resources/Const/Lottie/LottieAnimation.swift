
import UIKit
import Lottie

class ScrollLottieAnimation {
    
    // Static method to create the Lottie animation view
    static func createScrollAnimationView() -> UIView {
        // Create the Lottie view first
        let lottieView = LottieAnimationView()
        
        // Get animation data
        let animationData = getScrollAnimationData()
        
        // Convert JSON string to Data
        guard let jsonData = animationData.data(using: .utf8) else {
            print("❌ Failed to convert JSON string to data")
            return createFallbackAnimationView()
        }
        
        // Create animation from JSON data
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: jsonData, options: [])
            
            // Create a temporary file to load the animation
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("scroll_animation.json")
            try jsonData.write(to: tempURL)
            
            // Load animation from the temporary file
            let animation = LottieAnimation.filepath(tempURL.path)
            lottieView.animation = animation
            
            // Clean up the temporary file
            try? FileManager.default.removeItem(at: tempURL)
            
        } catch {
            print("❌ Failed to create Lottie animation: \(error)")
            return createFallbackAnimationView()
        }
        
        // Configure the animation
        lottieView.loopMode = LottieLoopMode.loop
        lottieView.animationSpeed = 1.0
        lottieView.contentMode = UIView.ContentMode.scaleAspectFit
        
        // Set size constraints for Lottie view (using original 90x92 size)
        lottieView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            lottieView.widthAnchor.constraint(equalToConstant: 90),
            lottieView.heightAnchor.constraint(equalToConstant: 92)
        ])
        
        // Start playing the animation
        lottieView.play()
        
        print("✅ Lottie scroll animation created and playing")
        return lottieView
    }
    
    // Private method to get the Lottie JSON data
    private static func getScrollAnimationData() -> String {
        return """
        {"nm":"Pre-comp 1","ddd":0,"h":92,"w":90,"meta":{"g":"@lottiefiles/toolkit-js 0.33.2"},"layers":[{"ty":0,"nm":"Scroll","sr":1,"st":0,"op":900.000036657751,"ip":0,"hd":false,"ddd":0,"bm":0,"hasMask":false,"ao":0,"ks":{"a":{"a":0,"k":[45,46,0],"ix":1},"s":{"a":0,"k":[100,100,100],"ix":6},"sk":{"a":0,"k":0},"p":{"a":0,"k":[45,46,0],"ix":2},"r":{"a":0,"k":0,"ix":10},"sa":{"a":0,"k":0},"o":{"a":0,"k":100,"ix":11}},"ef":[],"w":90,"h":92,"refId":"comp_0","ind":1}],"v":"5.5.7","fr":29.9700012207031,"op":78.0000031770051,"ip":30.0000012219251,"assets":[{"nm":"","id":"comp_0","layers":[{"ty":4,"nm":"Scroll Outlines 4","sr":1,"st":70.0000028511585,"op":117.000004765508,"ip":70.0000028511585,"hd":false,"ddd":0,"bm":0,"hasMask":false,"ao":0,"ks":{"a":{"a":0,"k":[45,46,0],"ix":1},"s":{"a":1,"k":[{"o":{"x":0.333,"y":0},"i":{"x":0.833,"y":0.833},"s":[70,70,100],"t":70},{"o":{"x":0.167,"y":0.167},"i":{"x":0.833,"y":0.833},"s":[80,80,100],"t":85},{"o":{"x":0.333,"y":0},"i":{"x":0.833,"y":0.833},"s":[80,80,100],"t":101},{"s":[70,70,100],"t":116.000004724777}],"ix":6},"sk":{"a":0,"k":0},"p":{"a":1,"k":[{"o":{"x":0.333,"y":0},"i":{"x":0.667,"y":1},"s":[44.75,34.5,0],"t":70,"ti":[0,-4.583,0],"to":[0,4.583,0]},{"s":[44.75,62,0],"t":116.000004724777}],"ix":2},"r":{"a":0,"k":0,"ix":10},"sa":{"a":0,"k":0},"o":{"a":1,"k":[{"o":{"x":0.333,"y":0},"i":{"x":0.667,"y":1},"s":[0],"t":70},{"o":{"x":0.333,"y":0},"i":{"x":0.667,"y":1},"s":[100],"t":85},{"o":{"x":0.333,"y":0},"i":{"x":0.667,"y":1},"s":[100],"t":101},{"s":[0],"t":116.000004724777}],"ix":11}},"ef":[],"shapes":[{"ty":"gr","bm":0,"hd":false,"mn":"ADBE Vector Group","nm":"Group 1","ix":1,"cix":2,"np":2,"it":[{"ty":"sh","bm":0,"hd":false,"mn":"ADBE Vector Shape - Group","nm":"Path 1","ix":1,"d":1,"ks":{"a":0,"k":{"c":true,"i":[[1.172,1.171],[1.171,-1.172],[0,0],[0,0],[1.171,-1.172],[-1.172,-1.172],[0,0],[-0.929,0.162],[-0.716,0.717],[0,0]],"o":[[-1.171,-1.172],[0,0],[0,0],[-1.172,-1.172],[-1.172,1.171],[0,0],[0.718,0.717],[0.928,0.162],[0,0],[1.172,-1.172]],"v":[[19.607,-10.516],[15.365,-10.516],[0.001,4.848],[-15.364,-10.516],[-19.607,-10.516],[-19.607,-6.273],[-2.637,10.697],[0.001,11.526],[2.635,10.697],[19.607,-6.273]]},"ix":2}},{"ty":"fl","bm":0,"hd":false,"mn":"ADBE Vector Graphic - Fill","nm":"Fill 1","c":{"a":0,"k":[1,0.4,0],"ix":4},"r":1,"o":{"a":0,"k":100,"ix":5}},{"ty":"tr","a":{"a":0,"k":[0,0],"ix":1},"s":{"a":0,"k":[100,100],"ix":3},"sk":{"a":0,"k":0,"ix":4},"p":{"a":0,"k":[45,47.893],"ix":2},"r":{"a":0,"k":0,"ix":6},"sa":{"a":0,"k":0,"ix":5},"o":{"a":0,"k":100,"ix":7}}]}],"ind":1},{"ty":4,"nm":"Scroll Outlines 3","sr":1,"st":47.0000019143492,"op":94.0000038286985,"ip":47.0000019143492,"hd":false,"ddd":0,"bm":0,"hasMask":false,"ao":0,"ks":{"a":{"a":0,"k":[45,46,0],"ix":1},"s":{"a":1,"k":[{"o":{"x":0.333,"y":0},"i":{"x":0.833,"y":0.833},"s":[70,70,100],"t":47},{"o":{"x":0.167,"y":0.167},"i":{"x":0.833,"y":0.833},"s":[80,80,100],"t":62},{"o":{"x":0.333,"y":0},"i":{"x":0.833,"y":0.833},"s":[80,80,100],"t":78},{"s":[70,70,100],"t":93.0000037879676}],"ix":6},"sk":{"a":0,"k":0},"p":{"a":1,"k":[{"o":{"x":0.333,"y":0},"i":{"x":0.667,"y":1},"s":[44.75,34.5,0],"t":47,"ti":[0,-4.583,0],"to":[0,4.583,0]},{"s":[44.75,62,0],"t":93.0000037879676}],"ix":2},"r":{"a":0,"k":0,"ix":10},"sa":{"a":0,"k":0},"o":{"a":1,"k":[{"o":{"x":0.333,"y":0},"i":{"x":0.667,"y":1},"s":[0],"t":47},{"o":{"x":0.333,"y":0},"i":{"x":0.667,"y":1},"s":[100],"t":62},{"o":{"x":0.333,"y":0},"i":{"x":0.667,"y":1},"s":[100],"t":78},{"s":[0],"t":93.0000037879676}],"ix":11}},"ef":[],"shapes":[{"ty":"gr","bm":0,"hd":false,"mn":"ADBE Vector Group","nm":"Group 1","ix":1,"cix":2,"np":2,"it":[{"ty":"sh","bm":0,"hd":false,"mn":"ADBE Vector Shape - Group","nm":"Path 1","ix":1,"d":1,"ks":{"a":0,"k":{"c":true,"i":[[1.172,1.171],[1.171,-1.172],[0,0],[0,0],[1.171,-1.172],[-1.172,-1.172],[0,0],[-0.929,0.162],[-0.716,0.717],[0,0]],"o":[[-1.171,-1.172],[0,0],[0,0],[-1.172,-1.172],[-1.172,1.171],[0,0],[0.718,0.717],[0.928,0.162],[0,0],[1.172,-1.172]],"v":[[19.607,-10.516],[15.365,-10.516],[0.001,4.848],[-15.364,-10.516],[-19.607,-10.516],[-19.607,-6.273],[-2.637,10.697],[0.001,11.526],[2.635,10.697],[19.607,-6.273]]},"ix":2}},{"ty":"fl","bm":0,"hd":false,"mn":"ADBE Vector Graphic - Fill","nm":"Fill 1","c":{"a":0,"k":[1,0.4,0],"ix":4},"r":1,"o":{"a":0,"k":100,"ix":5}},{"ty":"tr","a":{"a":0,"k":[0,0],"ix":1},"s":{"a":0,"k":[100,100],"ix":3},"sk":{"a":0,"k":0,"ix":4},"p":{"a":0,"k":[45,47.893],"ix":2},"r":{"a":0,"k":0,"ix":6},"sa":{"a":0,"k":0,"ix":5},"o":{"a":0,"k":100,"ix":7}}]}],"ind":2},{"ty":4,"nm":"Scroll Outlines 2","sr":1,"st":23.0000009368092,"op":70.0000028511584,"ip":23.0000009368092,"hd":false,"ddd":0,"bm":0,"hasMask":false,"ao":0,"ks":{"a":{"a":0,"k":[45,46,0],"ix":1},"s":{"a":1,"k":[{"o":{"x":0.333,"y":0},"i":{"x":0.833,"y":0.833},"s":[70,70,100],"t":23},{"o":{"x":0.167,"y":0.167},"i":{"x":0.833,"y":0.833},"s":[80,80,100],"t":38},{"o":{"x":0.333,"y":0},"i":{"x":0.833,"y":0.833},"s":[80,80,100],"t":54},{"s":[70,70,100],"t":69.0000028104276}],"ix":6},"sk":{"a":0,"k":0},"p":{"a":1,"k":[{"o":{"x":0.333,"y":0},"i":{"x":0.667,"y":1},"s":[44.75,34.5,0],"t":23,"ti":[0,-4.583,0],"to":[0,4.583,0]},{"s":[44.75,62,0],"t":69.0000028104276}],"ix":2},"r":{"a":0,"k":0,"ix":10},"sa":{"a":0,"k":0},"o":{"a":1,"k":[{"o":{"x":0.333,"y":0},"i":{"x":0.667,"y":1},"s":[0],"t":23},{"o":{"x":0.333,"y":0},"i":{"x":0.667,"y":1},"s":[100],"t":38},{"o":{"x":0.333,"y":0},"i":{"x":0.667,"y":1},"s":[100],"t":54},{"s":[0],"t":69.0000028104276}],"ix":11}},"ef":[],"shapes":[{"ty":"gr","bm":0,"hd":false,"mn":"ADBE Vector Group","nm":"Group 1","ix":1,"cix":2,"np":2,"it":[{"ty":"sh","bm":0,"hd":false,"mn":"ADBE Vector Shape - Group","nm":"Path 1","ix":1,"d":1,"ks":{"a":0,"k":{"c":true,"i":[[1.172,1.171],[1.171,-1.172],[0,0],[0,0],[1.171,-1.172],[-1.172,-1.172],[0,0],[-0.929,0.162],[-0.716,0.717],[0,0]],"o":[[-1.171,-1.172],[0,0],[0,0],[-1.172,-1.172],[-1.172,1.171],[0,0],[0.718,0.717],[0.928,0.162],[0,0],[1.172,-1.172]],"v":[[19.607,-10.516],[15.365,-10.516],[0.001,4.848],[-15.364,-10.516],[-19.607,-10.516],[-19.607,-6.273],[-2.637,10.697],[0.001,11.526],[2.635,10.697],[19.607,-6.273]]},"ix":2}},{"ty":"fl","bm":0,"hd":false,"mn":"ADBE Vector Graphic - Fill","nm":"Fill 1","c":{"a":0,"k":[1,0.4,0],"ix":4},"r":1,"o":{"a":0,"k":100,"ix":5}},{"ty":"tr","a":{"a":0,"k":[0,0],"ix":1},"s":{"a":0,"k":[100,100],"ix":3},"sk":{"a":0,"k":0,"ix":4},"p":{"a":0,"k":[45,47.893],"ix":2},"r":{"a":0,"k":0,"ix":6},"sa":{"a":0,"k":0,"ix":5},"o":{"a":0,"k":100,"ix":7}}]}],"ind":3},{"ty":4,"nm":"Scroll Outlines","sr":1,"st":0,"op":47.0000019143492,"ip":0,"hd":false,"ddd":0,"bm":0,"hasMask":false,"ao":0,"ks":{"a":{"a":0,"k":[45,46,0],"ix":1},"s":{"a":1,"k":[{"o":{"x":0.333,"y":0},"i":{"x":0.833,"y":0.833},"s":[70,70,100],"t":0},{"o":{"x":0.167,"y":0.167},"i":{"x":0.833,"y":0.833},"s":[80,80,100],"t":15},{"o":{"x":0.333,"y":0},"i":{"x":0.833,"y":0.833},"s":[80,80,100],"t":31},{"s":[70,70,100],"t":46.0000018736184}],"ix":6},"sk":{"a":0,"k":0},"p":{"a":1,"k":[{"o":{"x":0.333,"y":0},"i":{"x":0.667,"y":1},"s":[44.75,34.5,0],"t":0,"ti":[0,-4.583,0],"to":[0,4.583,0]},{"s":[44.75,62,0],"t":46.0000018736184}],"ix":2},"r":{"a":0,"k":0,"ix":10},"sa":{"a":0,"k":0},"o":{"a":1,"k":[{"o":{"x":0.333,"y":0},"i":{"x":0.667,"y":1},"s":[0],"t":0},{"o":{"x":0.333,"y":0},"i":{"x":0.667,"y":1},"s":[100],"t":15},{"o":{"x":0.333,"y":0},"i":{"x":0.667,"y":1},"s":[100],"t":31},{"s":[0],"t":46.0000018736184}],"ix":11}},"ef":[],"shapes":[{"ty":"gr","bm":0,"hd":false,"mn":"ADBE Vector Group","nm":"Group 1","ix":1,"cix":2,"np":2,"it":[{"ty":"sh","bm":0,"hd":false,"mn":"ADBE Vector Shape - Group","nm":"Path 1","ix":1,"d":1,"ks":{"a":0,"k":{"c":true,"i":[[1.172,1.171],[1.171,-1.172],[0,0],[0,0],[1.171,-1.172],[-1.172,-1.172],[0,0],[-0.929,0.162],[-0.716,0.717],[0,0]],"o":[[-1.171,-1.172],[0,0],[0,0],[-1.172,-1.172],[-1.172,1.171],[0,0],[0.718,0.717],[0.928,0.162],[0,0],[1.172,-1.172]],"v":[[19.607,-10.516],[15.365,-10.516],[0.001,4.848],[-15.364,-10.516],[-19.607,-10.516],[-19.607,-6.273],[-2.637,10.697],[0.001,11.526],[2.635,10.697],[19.607,-6.273]]},"ix":2}},{"ty":"fl","bm":0,"hd":false,"mn":"ADBE Vector Graphic - Fill","nm":"Fill 1","c":{"a":0,"k":[1,0.4,0],"ix":4},"r":1,"o":{"a":0,"k":100,"ix":5}},{"ty":"tr","a":{"a":0,"k":[0,0],"ix":1},"s":{"a":0,"k":[100,100],"ix":3},"sk":{"a":0,"k":0,"ix":4},"p":{"a":0,"k":[45,47.893],"ix":2},"r":{"a":0,"k":0,"ix":6},"sa":{"a":0,"k":0,"ix":5},"o":{"a":0,"k":100,"ix":7}}]}],"ind":4}]}]}
        """
    }
    
    // Fallback animation view in case Lottie is not available - white scroll icon for blue background
    private static func createFallbackAnimationView() -> UIView {
        let containerView = UIView()
        containerView.backgroundColor = UIColor.clear
        
        // Create a simple animated scroll icon as fallback (white color for blue background)
        let scrollImageView = UIImageView()
        scrollImageView.image = UIImage(systemName: "scroll")
        scrollImageView.tintColor = UIColor.white // White for blue background
        scrollImageView.contentMode = .scaleAspectFit
        scrollImageView.translatesAutoresizingMaskIntoConstraints = false
        
        containerView.addSubview(scrollImageView)
        NSLayoutConstraint.activate([
            scrollImageView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            scrollImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            scrollImageView.widthAnchor.constraint(equalToConstant: 40),
            scrollImageView.heightAnchor.constraint(equalToConstant: 40)
        ])
        
        // Simple bounce animation
        let bounceAnimation = CAKeyframeAnimation(keyPath: "transform.scale")
        bounceAnimation.values = [1.0, 1.2, 1.0, 0.8, 1.0]
        bounceAnimation.duration = 1.5
        bounceAnimation.repeatCount = .infinity
        bounceAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        scrollImageView.layer.add(bounceAnimation, forKey: "bounce")
        
        return containerView
    }
}
