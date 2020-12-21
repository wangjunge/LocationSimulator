//
//  ProgressView.swift
//  LocationSimulator
//
//  Created by David Klopp on 21.12.20.
//  Copyright © 2020 David Klopp. All rights reserved.
//

import AppKit
import Downloader

class ProgressView: NSView {
    /// Label above the download bar at the top.
    @IBOutlet weak var statusLabelTop: NSTextField!
    /// Label above the download bar at the bottom.
    @IBOutlet weak var statusLabelBottom: NSTextField!
    /// Download bar at the top of the window.
    @IBOutlet weak var progressBarTop: NSProgressIndicator!
    /// Download bar at the bottom of the window.
    @IBOutlet weak var progressBarBottom: NSProgressIndicator!
    /// The contentView containing the status elements.
    @IBOutlet var contentView: NSView!

    /// The downloader instance to manage.
    public let downloader: Downloader = Downloader()

    /// True if the download progress is active.
    private var isDownloading = false

    /// The DeveloperDiskImage download task.
    private var devDiskTask: DownloadTask?

    /// The DeveloperDiskImageSignature download task.
    private var devSignTask: DownloadTask?

    // MARK: - Constructor

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.downloader.delegate = self
        self.setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not available")
    }

    private func setup() {
        // Load the contentView and set its size to update automatically.
        Bundle.main.loadNibNamed("ProgressView", owner: self, topLevelObjects: nil)
        self.contentView.autoresizingMask = [.width, .height]
        self.contentView.translatesAutoresizingMaskIntoConstraints = true
        self.contentView.frame = self.bounds
        self.addSubview(self.contentView)
    }

    // MARK: - Download

    /// Prepare the download for the developer disk images.
    /// - Parameter os: the os type to download the image for
    /// - Parameter iOSVersion: the version number to download the image for
    /// - Return: true if the download can be started, false otherwise
    public func prepareDownload(os: String, iOSVersion: String) -> Bool {
        // Check if the path for the image and signature file can be created.
        let manager = FileManager.default
        guard let devDMG = manager.getDeveloperDiskImage(os: os, iOSVersion: iOSVersion),
              let devSign = manager.getDeveloperDiskImageSignature(os: os, iOSVersion: iOSVersion) else {
            return false
        }

        // Get the download links from the internal plist file.
        let (diskLinks, signLinks) = manager.getDeveloperDiskImageDownloadLinks(os: os, version: iOSVersion)
        if diskLinks.isEmpty || signLinks.isEmpty {
            return false
        }

        // We use the first download link. In theory we could add multiple links for the same image.
        self.devDiskTask = DownloadTask(dID: kDevDiskTaskID, source: diskLinks[0], destination: devDMG,
                                       description: NSLocalizedString("DEVDISK_DOWNLOAD_DESC", comment: ""))
        self.devSignTask = DownloadTask(dID: kDevSignTaskID, source: signLinks[0], destination: devSign,
                                       description: NSLocalizedString("DEVSIGN_DOWNLOAD_DESC", comment: ""))

        return true
    }

    /// Start the download of the DeveloperDiskImages.
    /// - Return: true on success, false otherwise.
    public func startDownload() -> Bool {
        guard !self.isDownloading, let devDiskTask = self.devDiskTask, let devSignTask = self.devSignTask else {
            return false
        }

        self.isDownloading = true

        // Start the downlaod process.
        self.downloader.start(devDiskTask)
        self.downloader.start(devSignTask)
        return true
    }

    /// Cancel the current download.
    /// - Return: true on success, false otherwise.
    public func cancelDownload() -> Bool {
        guard self.isDownloading, let devDiskTask = self.devDiskTask, let devSignTask = self.devSignTask else {
            return false
        }
        self.downloader.cancel(devDiskTask)
        self.downloader.cancel(devSignTask)

        // Cleanup
        self.isDownloading = false
        self.devSignTask = nil
        self.devSignTask = nil
        return true
    }
}
